# frozen_string_literal: true

module Mutations
  module Ci
    module PipelineSchedule
      class Delete < Base
        graphql_name 'PipelineScheduleDelete'

        authorize :admin_pipeline_schedule
        authorize_granular_token permissions: :delete_pipeline_schedule, boundary_argument: :id, boundary_type: :project

        def resolve(id:)
          schedule = authorized_find!(id: id)

          if schedule.destroy
            {
              errors: []
            }
          else
            {
              errors: ['Failed to remove the pipeline schedule']
            }
          end
        end
      end
    end
  end
end
