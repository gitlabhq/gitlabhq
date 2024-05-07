# frozen_string_literal: true

module Mutations
  module Ci
    module PipelineSchedule
      class TakeOwnership < Base
        graphql_name 'PipelineScheduleTakeOwnership'

        authorize :admin_pipeline_schedule

        field :pipeline_schedule,
          Types::Ci::PipelineScheduleType,
          description: 'Updated pipeline schedule ownership.'

        def resolve(id:)
          schedule = authorized_find!(id: id)

          service_response = ::Ci::PipelineSchedules::TakeOwnershipService.new(schedule, current_user).execute
          {
            pipeline_schedule: schedule,
            errors: service_response.errors
          }
        end
      end
    end
  end
end
