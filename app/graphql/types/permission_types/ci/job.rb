# frozen_string_literal: true

module Types
  module PermissionTypes
    module Ci
      class Job < BasePermissionType
        graphql_name 'JobPermissions'

        abilities :read_job_artifacts, :read_build
        ability_field :update_build, calls_gitaly: true
        ability_field :cancel_build, calls_gitaly: true
      end
    end
  end
end
