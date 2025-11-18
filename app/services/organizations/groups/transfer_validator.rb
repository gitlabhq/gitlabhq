# frozen_string_literal: true

module Organizations
  module Groups
    class TransferValidator
      include ActiveModel::Validations
      include Concerns::ValidateUserTransfer

      def initialize(group:, new_organization:, current_user:)
        @group = group
        @new_organization = new_organization
        @current_user = current_user
      end

      def can_transfer?
        error_message.nil?
      end

      def error_message
        return localized_error_messages[:group_not_root] unless group_is_root?
        return localized_error_messages[:same_organization] if same_organization?
        return localized_error_messages[:permission] unless has_permission?
        return cannot_transfer_users_error unless can_transfer_users?

        nil
      end

      private

      attr_reader :group, :new_organization, :current_user

      def users
        group.users_with_descendants
      end

      def group_is_root?
        !group.has_parent?
      end

      def same_organization?
        new_organization && new_organization.id == group.organization_id
      end

      def has_permission?
        return false unless Ability.allowed?(current_user, :admin_group, group)
        return false unless Ability.allowed?(current_user, :admin_organization, new_organization)

        true
      end

      def localized_error_messages
        {
          group_not_root: s_('TransferOrganization|Only root groups can be transferred to a different organization.'),
          same_organization: s_('TransferOrganization|Group is already in the target organization.'),
          permission: s_("TransferOrganization|You must be an owner of both the group and new organization.")
        }.freeze
      end
    end
  end
end
