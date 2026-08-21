# frozen_string_literal: true

module Types
  module PermissionTypes
    class OrganizationUser < BasePermissionType
      graphql_name 'OrganizationUserPermissions'

      abilities :delete_organization_user, :admin_organization

      def admin_organization
        Ability.allowed?(context[:current_user], :update_organization, object)
      end
    end
  end
end
