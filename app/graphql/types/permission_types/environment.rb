# frozen_string_literal: true

module Types
  module PermissionTypes
    class Environment < BasePermissionType
      graphql_name 'EnvironmentPermissions'

      abilities :update_environment, :destroy_environment, :stop_environment
    end
  end
end
