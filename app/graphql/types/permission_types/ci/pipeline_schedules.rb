# frozen_string_literal: true

module Types
  module PermissionTypes
    module Ci
      class PipelineSchedules < BasePermissionType
        graphql_name 'PipelineSchedulePermissions'

        abilities :take_ownership_pipeline_schedule,
                  :update_pipeline_schedule,
                  :admin_pipeline_schedule

        ability_field :play_pipeline_schedule, calls_gitaly: true
      end
    end
  end
end
