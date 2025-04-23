# frozen_string_literal: true

module Types
  module PermissionTypes
    module Members
      class GroupMember < BasePermissionType
        graphql_name 'GroupMemberPermissions'

        abilities :read_group, :create_projects, :create_custom_emoji, :remove_group, :view_edit_page
      end
    end
  end
end
