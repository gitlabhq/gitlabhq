# frozen_string_literal: true

module Organizations
  module Groups
    class TransferService
      include Gitlab::Utils::StrongMemoize

      TransferError = Class.new(StandardError)
      BATCH_SIZE = 50

      def initialize(group:, new_organization:, current_user:)
        @group = group
        @new_organization = new_organization
        @current_user = current_user
      end

      def async_execute
        return ServiceResponse.error(message: transfer_error) unless can_transfer?

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
        return ServiceResponse.error(message: transfer_error) unless can_transfer?

        # Find or create bot users before transaction to avoid exclusive lease errors.
        # If the transaction is rolled back, new bots will still exist
        # but this does not affect data integrity
        user_transfer_service.prepare_bots

        Group.transaction do
          transfer_namespaces_and_projects
          transfer_users
        end

        log_transfer_success
        ServiceResponse.success
      rescue StandardError => e
        log_transfer_error(e.message)
        ServiceResponse.error(message: e.message)
      end

      private

      attr_reader :group, :new_organization, :current_user

      def transfer_namespaces_and_projects
        # `skope: Namespace` ensures we get both Group and ProjectNamespace types
        descendant_ids = group.self_and_descendant_ids(skope: Namespace)

        descendant_ids.in_groups_of(BATCH_SIZE, false) do |batch_ids|
          Namespace.id_in(batch_ids).update_all(
            organization_id: new_organization.id,
            visibility_level: Arel.sql('LEAST(?, visibility_level)', new_organization.visibility_level)
          )
          Project.in_namespace(batch_ids).update_all(
            organization_id: new_organization.id,
            visibility_level: Arel.sql('LEAST(?, visibility_level)', new_organization.visibility_level)
          )
        end
      end

      def transfer_users
        user_transfer_service.execute
      end

      def user_transfer_service
        @user_transfer_service ||= Organizations::Users::TransferService.new(
          users: users,
          new_organization: new_organization
        )
      end

      def users
        group.users_with_descendants
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
        return true if group_is_root? && !already_transferred? && has_permission? && can_transfer_users?

        false
      end

      def transfer_error
        error = localized_error_messages[:group_not_root] unless group_is_root?
        error ||= localized_error_messages[:already_transferred] if already_transferred?
        error ||= localized_error_messages[:permission] unless has_permission?
        error ||= user_transfer_error unless can_transfer_users?

        format(
          s_("TransferOrganization|Group organization transfer failed: %{error_message}"),
          error_message: error
        )
      end

      def group_is_root?
        !group.has_parent?
      end

      def already_transferred?
        new_organization && new_organization.id == group.organization_id
      end

      def has_permission?
        return false unless Ability.allowed?(current_user, :admin_group, group)
        return false unless Ability.allowed?(current_user, :admin_organization, new_organization)

        true
      end

      def can_transfer_users?
        user_transfer_service.can_transfer_users?
      end

      def user_transfer_error
        user_transfer_service.transfer_error
      end

      def localized_error_messages
        {
          group_not_root: s_('TransferOrganization|Only root groups can be transferred to a different organization.'),
          already_transferred: s_('TransferOrganization|Group is already in the target organization.'),
          permission: s_("TransferOrganization|You must be an owner of both the group and new organization.")
        }.freeze
      end
    end
  end
end
