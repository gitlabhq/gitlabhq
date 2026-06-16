# frozen_string_literal: true

module Organizations
  module Transfer
    class TopLevelGroupService
      include BaseServiceUtility

      BATCH_SIZE = 100

      def initialize(groups:, new_organization:, current_user:, skip_authorization: false)
        @groups = Array(groups)
        @new_organization = new_organization
        @current_user = current_user
        @skip_authorization = skip_authorization
      end

      def execute
        return ServiceResponse.error(message: organization_not_found_error) unless new_organization.present?
        return ServiceResponse.error(message: permission_error) unless can_transfer_to_organization?

        preload_associations

        validation_errors = validate_all_groups
        if validation_errors.any?
          return ServiceResponse.error(message: build_validation_error_message(validation_errors),
            payload: { failed: validation_errors })
        end

        transferred_ids = []

        Group.transaction do
          groups.each_slice(BATCH_SIZE) do |batch|
            batch_ids = batch.map(&:id)
            Group.id_in(batch_ids).update_all(organization_id: new_organization.id)
            transferred_ids.concat(batch_ids)
          end
        end

        groups.each { |group| log_transfer_success(group) }

        ServiceResponse.success(payload: { succeeded: transferred_ids, failed: {} })
      end

      private

      attr_reader :groups, :new_organization, :current_user, :skip_authorization

      def preload_associations
        ActiveRecord::Associations::Preloader.new(
          records: groups,
          associations: [:route]
        ).call

        Preloaders::GroupPolicyPreloader.new(groups, current_user).execute
      end

      def can_transfer_to_organization?
        skip_authorization || Ability.allowed?(current_user, :transfer_group, new_organization)
      end

      def validate_all_groups
        errors = {}

        DeclarativePolicy.user_scope do
          groups.each do |group|
            error = error_message_for_group(group)
            next unless error

            errors[group.id] = error
            log_transfer_error(group, error)
          end
        end

        errors
      end

      def error_message_for_group(group)
        return group_not_root_error unless group_is_root?(group)
        return if skip_authorization

        permission_error unless Ability.allowed?(current_user, :update_group_organization, group)
      end

      def group_is_root?(group)
        group.root?
      end

      def group_not_root_error
        s_('TransferOrganization|Only top-level groups can be transferred to a different organization.')
      end

      def permission_error
        s_("TransferOrganization|You must be an owner of both the group and new organization.")
      end

      def organization_not_found_error
        format(
          s_("TransferOrganization|Top-level group organization transfer failed: %{error_message}"),
          error_message: s_('TransferOrganization|Target organization must be specified.')
        )
      end

      def build_validation_error_message(errors)
        format(
          s_("TransferOrganization|Failed to transfer %{failed_count} of %{total_count} groups"),
          failed_count: errors.size,
          total_count: groups.size
        )
      end

      def log_transfer_success(group)
        ::Gitlab::AppLogger.info(log_transfer_payload(
          group: group,
          message: "Top-level group was transferred to a new organization"
        ))
      end

      def log_transfer_error(group, error_message)
        ::Gitlab::AppLogger.error(log_transfer_payload(
          group: group,
          message: "Top-level group was not transferred to a new organization",
          error_message: error_message
        ))
      end

      def log_transfer_payload(group:, message:, error_message: nil)
        {
          message: message,
          group_path: group.full_path,
          group_id: group.id,
          new_organization_path: new_organization.full_path,
          new_organization_id: new_organization.id,
          error_message: error_message
        }
      end
    end
  end
end

Organizations::Transfer::TopLevelGroupService.prepend_mod
