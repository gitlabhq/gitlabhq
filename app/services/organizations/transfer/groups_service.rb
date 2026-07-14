# frozen_string_literal: true

module Organizations
  module Transfer
    class GroupsService
      include Gitlab::Utils::StrongMemoize
      include Organizations::Transfer::Concerns::OrganizationUpdater

      TransferError = Class.new(StandardError)
      BATCH_SIZE = 50

      def initialize(group:, new_organization:, current_user:)
        @group = group
        @new_organization = new_organization
        @current_user = current_user
      end

      def async_execute
        return ServiceResponse.error(message: transfer_error, reason: transfer_error_reason) unless can_transfer?

        Organizations::Groups::TransferWorker.perform_async(
          {
            'group_id' => group.id,
            'organization_id' => new_organization.id,
            'current_user_id' => current_user.id
          }
        )

        ServiceResponse.success(
          message: s_("TransferOrganization|Group transfer to organization initiated")
        )
      end

      def execute
        return ServiceResponse.error(message: transfer_error, reason: transfer_error_reason) unless can_transfer?

        Group.transaction do
          perform_transfer
        end

        log_transfer_success
        ServiceResponse.success
      rescue StandardError => e
        log_transfer_error(e.message)
        ServiceResponse.error(message: e.message)
      end

      private

      attr_reader :group, :new_organization, :current_user

      # The "old" organization is the source of the transfer. By default it is
      # the group's current organization, but Organizations::ConfirmService
      # moves the top-level group's organization_id ahead of the descendants;
      # in that case the actual source is taken from the first descendant
      # that has not yet been transferred so the runners transfer, the
      # GroupTransferredEvent, and the EE subscription transfer all receive
      # the real source organization.
      def old_organization
        return group.organization unless new_organization&.id == group.organization_id

        Organizations::Organization.find_by_id(untransferred_descendant_organization_id) ||
          group.organization
      end
      strong_memoize_attr :old_organization

      def untransferred_descendant_organization_id
        descendant_ids = group.self_and_descendant_ids(skope: Namespace)

        Namespace.id_in(descendant_ids)
          .where.not(organization_id: new_organization.id) # rubocop:disable CodeReuse/ActiveRecord -- used only in this service
          .limit(1)
          .pick(:organization_id)
      end

      def perform_transfer
        transfer_namespaces_and_projects
        schedule_ci_runners_transfer
        publish_event
      end

      def transfer_namespaces_and_projects
        # `skope: Namespace` ensures we get both Group and ProjectNamespace types
        descendant_ids = group.self_and_descendant_ids(skope: Namespace)

        descendant_ids.in_groups_of(BATCH_SIZE, false) do |batch_ids|
          Namespace.id_in(batch_ids).update_all(
            organization_id: new_organization.id,
            visibility_level: Arel.sql('LEAST(?, visibility_level)', new_organization.visibility_level)
          )
          project_relation = Project.in_namespace(batch_ids)
          project_relation.each_batch(of: BATCH_SIZE) do |batch|
            schedule_pool_repository_disconnections(batch)
          end

          transfer_fork_networks(project_relation.select(:id))

          project_relation.update_all(
            organization_id: new_organization.id,
            visibility_level: Arel.sql('LEAST(?, visibility_level)', new_organization.visibility_level)
          )

          transfer_oauth_applications(batch_ids)
        end
      end

      # rubocop:disable CodeReuse/ActiveRecord -- used only in this service
      def transfer_oauth_applications(namespace_ids)
        update_organization_id_for(Authn::OauthApplication) do |relation|
          relation.where(owner_type: 'Namespace', owner_id: namespace_ids)
        end
      end
      # rubocop:enable CodeReuse/ActiveRecord

      # rubocop:disable CodeReuse/ActiveRecord -- used only in this service
      def transfer_fork_networks(project_ids)
        ForkNetwork.where(root_project_id: project_ids).update_all(organization_id: new_organization.id)
      end
      # rubocop:enable CodeReuse/ActiveRecord

      # rubocop:disable CodeReuse/ActiveRecord -- used only in this service
      def schedule_pool_repository_disconnections(batch)
        group.run_after_commit_or_now do
          batch.where.not(pool_repository_id: nil).select(:id).each do |project|
            Repositories::LeavePoolRepositoryWorker.perform_async(project.id)
          end
        end
      end
      # rubocop:enable CodeReuse/ActiveRecord

      def publish_event
        # Capture IDs before the block: instance_eval in run_after_commit_or_now
        # changes self to the group object, so attr_reader methods would not resolve.
        group_id = group.id
        old_org_id = old_organization.id
        new_org_id = new_organization.id

        # Publish once for the root group only. Descendants implicitly move with it.
        # Subscribers that need to act on descendant projects must traverse them
        # independently (e.g. via NamespaceEachBatch).
        group.run_after_commit_or_now do
          Gitlab::EventStore.publish(
            Organizations::GroupTransferredEvent.new(data: {
              group_id: group_id,
              old_organization_id: old_org_id,
              new_organization_id: new_org_id
            })
          )
        end
      end

      def schedule_ci_runners_transfer
        group_id = group.id
        old_org_id = old_organization.id
        new_org_id = new_organization.id

        group.run_after_commit_or_now do
          ::Ci::Runners::TransferOrganizationWorker.perform_async(group_id, old_org_id, new_org_id)
        end
      end

      def log_transfer_success
        log_transfer
      end

      def log_transfer_error(error_message)
        log_transfer(error_message)
      end

      def log_transfer(error_message = nil)
        action = error_message.nil? ? "was" : "was not"

        log_payload = {
          message: "Group #{action} transferred to a new organization",
          group_path: @group.full_path,
          group_id: @group.id,
          new_organization_path: new_organization&.full_path,
          new_organization_id: new_organization&.id,
          error_message: error_message
        }

        if error_message.nil?
          ::Gitlab::AppLogger.info(log_payload)
        else
          ::Gitlab::AppLogger.error(log_payload)
        end
      end

      def can_transfer?
        return true if group_is_root? && !already_transferred? && has_permission?

        false
      end

      def transfer_error
        error = localized_error_messages[:group_not_root] unless group_is_root?
        error ||= localized_error_messages[:already_transferred] if already_transferred?
        error ||= localized_error_messages[:permission] unless has_permission?

        format(
          s_("TransferOrganization|Group organization transfer failed: %{error_message}"),
          error_message: error
        )
      end

      def transfer_error_reason
        return :group_not_root unless group_is_root?
        return :already_transferred if already_transferred?

        :missing_permission unless has_permission?
      end

      def group_is_root?
        !group.has_parent?
      end

      def already_transferred?
        new_organization && new_organization.id == old_organization.id
      end

      def has_permission?
        return false unless Ability.allowed?(current_user, :admin_group, group)
        return false unless Ability.allowed?(current_user, :update_organization, new_organization)

        true
      end

      def localized_error_messages
        {
          group_not_root: s_(
            'TransferOrganization|Only top-level groups can be transferred to a different organization.'
          ),
          already_transferred: s_('TransferOrganization|Group is already in the target organization.'),
          permission: s_("TransferOrganization|You must be an owner of both the group and new organization.")
        }.freeze
      end
    end
  end
end

Organizations::Transfer::GroupsService.prepend_mod
