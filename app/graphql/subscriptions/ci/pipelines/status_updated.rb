# frozen_string_literal: true

module Subscriptions # rubocop:disable Gitlab/BoundedContexts -- Existing module
  module Ci
    module Pipelines
      class StatusUpdated < ::Subscriptions::BaseSubscription
        include Gitlab::Graphql::Laziness

        argument :pipeline_id, ::Types::GlobalIDType[::Ci::Pipeline],
          required: true,
          description: 'Global ID of the pipeline.'

        payload_type Types::Ci::PipelineType

        def authorized?(pipeline_id:)
          pipeline = force(GitlabSchema.find_by_gid(pipeline_id))

          unauthorized! unless pipeline && Ability.allowed?(current_user, :read_pipeline, pipeline)

          true
        end
      end
    end
  end
end
