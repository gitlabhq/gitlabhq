# frozen_string_literal: true

module Types
  module PermissionTypes
    class Deployment < BasePermissionType
      graphql_name 'DeploymentPermissions'

      abilities :destroy_deployment
      ability_field :update_deployment, calls_gitaly: true
    end
  end
end

Types::PermissionTypes::Deployment.prepend_mod_with('Types::PermissionTypes::Deployment')
