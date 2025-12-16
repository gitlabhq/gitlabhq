# frozen_string_literal: true

module Subscriptions
  module Ci
    module Stages
      class JobsUpdated < ::Subscriptions::BaseSubscription
        include Gitlab::Graphql::Laziness

        argument :stage_id, ::Types::GlobalIDType[::Ci::Stage],
          required: true,
          description: 'Global ID of the stage.'

        payload_type Types::Ci::JobType

        def authorized?(stage_id:)
          stage = force(GitlabSchema.find_by_gid(stage_id))

          unauthorized! unless stage && Ability.allowed?(current_user, :read_build, stage.project)

          true
        end

        def update(stage_id:)
          updated_job = object

          return NO_UPDATE unless updated_job

          # Verify the job actually belongs to this stage
          return NO_UPDATE unless updated_job.stage_id == stage_id.model_id.to_i

          updated_job
        end
      end
    end
  end
end
