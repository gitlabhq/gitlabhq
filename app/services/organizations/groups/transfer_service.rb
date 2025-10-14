# frozen_string_literal: true

module Organizations
  module Groups
    class TransferService
      include Gitlab::Utils::StrongMemoize

      TransferError = Class.new(StandardError)
      BATCH_SIZE = 50

      attr_accessor :error

      def initialize(group:, new_organization:, current_user:)
        @group = group
        @new_organization = new_organization
        @old_organization = @group.organization
        @current_user = current_user
      end

      def execute
        return ServiceResponse.error(message: error) unless transfer_allowed?

        Group.transaction do
          update_namespaces_and_projects
        end

        log_transfer_success
        ServiceResponse.success
      end

      private

      attr_reader :group, :new_organization, :old_organization, :current_user

      def update_namespaces_and_projects
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

      def transfer_allowed?
        return true if transfer_validator.can_transfer?

        error_message = transfer_validator.error_message

        self.error = format(
          s_("TransferOrganization|Group organization transfer failed: %{error_message}"),
          error_message: error_message
        )

        log_transfer_error(error_message)
        false
      end

      def transfer_validator
        Organizations::Groups::TransferValidator.new(
          group: group,
          new_organization: new_organization,
          current_user: current_user
        )
      end
      strong_memoize_attr :transfer_validator

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
    end
  end
end
