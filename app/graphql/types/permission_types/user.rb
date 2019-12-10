# frozen_string_literal: true

module Types
  module PermissionTypes
    class User < BasePermissionType
      graphql_name 'UserPermissions'

      permission_field :create_snippet

      def create_snippet
        Ability.allowed?(context[:current_user], :create_personal_snippet)
      end
    end
  end
end
