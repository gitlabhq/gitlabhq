# frozen_string_literal: true

module Subscriptions
  module Ci
    module PipelineSchedule
      class StatusUpdated < ::Subscriptions::BaseSubscription
        include Gitlab::Graphql::Laziness

        argument :project_id,
          ::Types::GlobalIDType[::Project],
          required: true,
          description: 'Global ID of the project.'

        payload_type Types::Ci::PipelineScheduleType

        def authorized?(project_id:)
          authorize_object_or_gid!(:read_pipeline_schedule, gid: project_id)
        end

        def update(project_id:)
          updated_schedule = object

          return NO_UPDATE unless updated_schedule
          return NO_UPDATE unless updated_schedule.project_id == project_id.model_id.to_i

          updated_schedule
        end
      end
    end
  end
end
