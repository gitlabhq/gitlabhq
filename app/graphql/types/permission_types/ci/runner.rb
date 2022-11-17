# frozen_string_literal: true

module Types
  module PermissionTypes
    module Ci
      class Runner < BasePermissionType
        graphql_name 'RunnerPermissions'

        abilities :read_runner, :update_runner, :delete_runner, :assign_runner
      end
    end
  end
end
