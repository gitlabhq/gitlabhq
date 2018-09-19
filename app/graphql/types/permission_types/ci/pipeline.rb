# frozen_string_literal: true

module Types
  module PermissionTypes
    module Ci
      class Pipeline < BasePermissionType
        graphql_name 'PipelinePermissions'

        abilities :update_pipeline, :admin_pipeline, :destroy_pipeline
      end
    end
  end
end
