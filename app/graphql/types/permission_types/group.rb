# frozen_string_literal: true

module Types
  module PermissionTypes
    class Group < BasePermissionType
      graphql_name 'GroupPermissions'

      abilities :read_group, :create_projects, :create_custom_emoji, :remove_group, :view_edit_page,
        :admin_issue, :read_crm_contact, :read_crm_organization

      permission_field :can_leave,
        description: 'If `true`, the user can leave this group.'

      def can_leave
        return false unless current_user

        current_user.can_leave_group?(object)
      end
    end
  end
end

::Types::PermissionTypes::Group.prepend_mod
