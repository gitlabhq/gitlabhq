# frozen_string_literal: true

module Organizations
  module Transfer
    class GroupsService
      include Gitlab::Utils::StrongMemoize
      include Organizations::Transfer::Concerns::OrganizationUpdater

      TransferError = Class.new(StandardError)
      BATCH_SIZE = 50
      SLACK_SCOPE_BATCH_LIMIT = 1_000

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

        # Capture log fields before the transaction. If the transfer fails, the
        # transaction is aborted and any DB read (e.g. group.full_path) would raise
        # PG::InFailedSqlTransaction during error logging.
        capture_log_context

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
        transfer_topics
        transfer_slack_api_scopes
        transfer_infrastructure
        schedule_ci_runners_transfer
        schedule_user_agent_details_transfer
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

        # update_all above bypasses callbacks, so capture the moved records explicitly.
        # TODO: evaluate moving this into OrganizationUpdater#update_organization_id_for.
        Authn::OauthApplication.record_iam_outbox_upserts(
          Authn::OauthApplication.where(
            owner_type: 'Namespace', owner_id: namespace_ids, organization_id: new_organization.id
          )
        )
      end
      # rubocop:enable CodeReuse/ActiveRecord

      # rubocop:disable CodeReuse/ActiveRecord -- used only in this service
      def transfer_fork_networks(project_ids)
        ForkNetwork.where(root_project_id: project_ids).update_all(organization_id: new_organization.id)
      end
      # rubocop:enable CodeReuse/ActiveRecord

      def transfer_topics
        Organizations::Transfer::TopicsService.new(
          group: group,
          old_organization: old_organization,
          new_organization: new_organization
        ).execute
      end

      # rubocop:disable CodeReuse/ActiveRecord -- scoped queries for duplication transfer
      def transfer_slack_api_scopes
        namespace_ids = group.self_and_descendant_ids(skope: Namespace)

        group_scope_ids = Integrations::SlackWorkspace::IntegrationApiScope
          .where(group_id: namespace_ids)
          .distinct
          .limit(SLACK_SCOPE_BATCH_LIMIT)
          .pluck(:slack_api_scope_id)

        project_scope_ids = Integrations::SlackWorkspace::IntegrationApiScope
          .where(project_id: group.all_projects)
          .distinct
          .limit(SLACK_SCOPE_BATCH_LIMIT)
          .pluck(:slack_api_scope_id)

        all_scope_ids = group_scope_ids | project_scope_ids

        old_scopes = Integrations::SlackWorkspace::ApiScope
          .where(id: all_scope_ids, organization_id: old_organization.id)

        old_scope_names = old_scopes.map(&:name)
        new_scopes = Integrations::SlackWorkspace::ApiScope
          .find_or_initialize_by_names(old_scope_names, organization_id: new_organization.id)

        name_to_new_id = new_scopes.index_by(&:name).transform_values(&:id)

        old_scopes.each do |old_scope|
          new_id = name_to_new_id[old_scope.name]

          Integrations::SlackWorkspace::IntegrationApiScope
            .where(group_id: namespace_ids, slack_api_scope_id: old_scope.id)
            .update_all(slack_api_scope_id: new_id)

          Integrations::SlackWorkspace::IntegrationApiScope
            .where(project_id: group.all_projects, slack_api_scope_id: old_scope.id)
            .update_all(slack_api_scope_id: new_id)
        end
      end
      # rubocop:enable CodeReuse/ActiveRecord

      def transfer_infrastructure
        transfer_burned_project_routes
        transfer_agent_organization_authorizations
      end

      # rubocop:disable CodeReuse/ActiveRecord -- used only in this service
      def transfer_burned_project_routes
        path_prefix = "#{group.full_path.downcase}/"
        like_pattern = "#{Authn::BurnedProjectRoute.sanitize_sql_like(path_prefix)}%"
        path_scope = ->(relation) { relation.where("LOWER(path) LIKE ?", like_pattern) }

        conflicting_paths = path_scope.call(
          Authn::BurnedProjectRoute.where(organization_id: new_organization.id)
        ).select("LOWER(path)")

        # Delete source-org burns that conflict with the target org - the target-org
        # row already protects the path. The surviving row's project_id may differ;
        # see https://gitlab.com/gitlab-org/gitlab/-/work_items/616401
        path_scope.call(
          Authn::BurnedProjectRoute.where(organization_id: old_organization.id)
        ).where("LOWER(path) IN (?)", conflicting_paths)
          .each_batch(of: ORGANIZATION_ID_UPDATE_BATCH_SIZE) { |batch| batch.delete_all }

        update_organization_id_for(Authn::BurnedProjectRoute, &path_scope)
      end
      # rubocop:enable CodeReuse/ActiveRecord

      # rubocop:disable CodeReuse/ActiveRecord -- used only in this service
      def transfer_agent_organization_authorizations
        descendant_agents = Clusters::Agent
          .joins(project: :namespace)
          .where("namespaces.traversal_ids @> ARRAY[?]::bigint[]", group.id)
          .where("cluster_agents.id = agent_organization_authorizations.agent_id")

        update_organization_id_for(
          Clusters::Agents::Authorizations::CiAccess::OrganizationAuthorization
        ) do |relation|
          relation.where_exists(descendant_agents)
        end
      end
      # rubocop:enable CodeReuse/ActiveRecord

      def projects
        Project.in_namespace(group.self_and_descendant_ids(skope: Namespace))
      end
      strong_memoize_attr :projects

      # rubocop:disable CodeReuse/ActiveRecord -- used only in this service
      def schedule_pool_repository_disconnections(batch)
        # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- bounded by each_batch
        project_ids = batch.where.not(pool_repository_id: nil).pluck(:id)
        # rubocop:enable Database/AvoidUsingPluckWithoutLimit

        return if project_ids.empty?

        # `group` never joins the transaction (all writes are `update_all`), so it cannot
        # carry an after-commit callback. Leaving a pool disconnects alternates in Gitaly
        # and nils pool_repository_id on the worker's connection; a rollback undoes neither.
        ActiveRecord.after_all_transactions_commit do
          project_ids.each { |project_id| Repositories::LeavePoolRepositoryWorker.perform_async(project_id) }
        end
      end
      # rubocop:enable CodeReuse/ActiveRecord

      def publish_event
        group_id = group.id
        old_org_id = old_organization.id
        new_org_id = new_organization.id

        # Publish once for the root group only. Descendants implicitly move with it.
        # Subscribers that need to act on descendant projects must traverse them
        # independently (e.g. via NamespaceEachBatch).
        #
        # `group` never joins the transaction (all writes are `update_all`), so it cannot
        # carry an after-commit callback. Subscribers read the transferred rows, so
        # publishing before commit makes them act on the old organization.
        ActiveRecord.after_all_transactions_commit do
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

        # `group` never joins the transaction (all writes are `update_all`), so it cannot
        # carry an after-commit callback. Defer so a rollback enqueues nothing.
        ActiveRecord.after_all_transactions_commit do
          ::Ci::Runners::TransferOrganizationWorker.perform_async(group_id, old_org_id, new_org_id)
        end
      end

      def schedule_user_agent_details_transfer
        group_id = group.id
        old_org_id = old_organization.id
        new_org_id = new_organization.id

        # `group` is never saved here - every write is `update_all` - so it cannot carry
        # an after-commit callback, and a caller may have wrapped us in its own
        # transaction. Defer to the outermost commit so a rollback enqueues nothing.
        ActiveRecord.after_all_transactions_commit do
          ::Organizations::TransferUserAgentDetailsWorker.perform_async(group_id, old_org_id, new_org_id)
        end
      end

      def log_transfer_success
        log_transfer
      end

      def log_transfer_error(error_message)
        log_transfer(error_message)
      end

      def capture_log_context
        @log_context = {
          group_path: group.full_path,
          group_id: group.id,
          new_organization_path: new_organization&.full_path,
          new_organization_id: new_organization&.id
        }
      end

      def log_transfer(error_message = nil)
        action = error_message.nil? ? "was" : "was not"

        log_payload = (@log_context || {}).merge(
          message: "Group #{action} transferred to a new organization",
          error_message: error_message
        )

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
