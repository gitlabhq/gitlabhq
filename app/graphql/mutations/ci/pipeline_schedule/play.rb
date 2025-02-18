# frozen_string_literal: true

module Mutations
  module Ci
    module PipelineSchedule
      class Play < Base
        graphql_name 'PipelineSchedulePlay'

        authorize :play_pipeline_schedule

        field :pipeline_schedule,
          Types::Ci::PipelineScheduleType,
          null: true,
          description: 'Pipeline schedule after mutation.'

        def resolve(id:)
          schedule = authorized_find!(id: id)

          job_id = ::Ci::PipelineSchedules::PlayService
            .new(schedule.project, current_user)
            .execute(schedule)

          if job_id
            { pipeline_schedule: schedule, errors: [] }
          else
            { pipeline_schedule: nil, errors: ['Unable to schedule a pipeline to run immediately.'] }
          end

        rescue Gitlab::Access::AccessDeniedError
          raise_resource_not_available_error!
        end
      end
    end
  end
end
