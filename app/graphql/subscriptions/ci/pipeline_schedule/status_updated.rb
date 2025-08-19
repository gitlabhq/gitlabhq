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
          project = force(GitlabSchema.find_by_gid(project_id))

          unauthorized! unless project
          unauthorized! unless Ability.allowed?(current_user, :read_pipeline_schedule, project)

          true
        end

        def update(project_id:)
          updated_schedule = object

          return NO_UPDATE unless updated_schedule

          project = force(GitlabSchema.find_by_gid(project_id))

          return NO_UPDATE unless project && updated_schedule.project_id == project.id
          return NO_UPDATE unless Ability.allowed?(current_user, :read_pipeline_schedule, updated_schedule)

          updated_schedule
        end
      end
    end
  end
end
