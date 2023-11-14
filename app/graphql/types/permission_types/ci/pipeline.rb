# frozen_string_literal: true

module Types
  module PermissionTypes
    module Ci
      class Pipeline < BasePermissionType
        graphql_name 'PipelinePermissions'

        abilities :admin_pipeline, :destroy_pipeline
        ability_field :update_pipeline, calls_gitaly: true
        ability_field :cancel_pipeline, calls_gitaly: true
      end
    end
  end
end
