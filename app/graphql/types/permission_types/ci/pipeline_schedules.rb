# frozen_string_literal: true

module Types
  module PermissionTypes
    module Ci
      class PipelineSchedules < BasePermissionType
        graphql_name 'PipelineSchedulePermissions'

        abilities :update_pipeline_schedule,
          :admin_pipeline_schedule

        ability_field :play_pipeline_schedule, calls_gitaly: true
        ability_field :take_ownership_pipeline_schedule,
          deprecated: {
            reason: 'Use admin_pipeline_schedule permission to determine if the user can take ownership ' \
              'of a pipeline schedule',
            milestone: '15.9'
          }
      end
    end
  end
end
