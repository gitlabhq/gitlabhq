# frozen_string_literal: true

module Types
  module PermissionTypes
    class OrganizationUser < BasePermissionType
      graphql_name 'OrganizationUserPermissions'

      abilities :remove_user, :delete_user, :admin_organization
    end
  end
end
