# frozen_string_literal: true

module Subscriptions
  module Ci
    module Pipelines
      class StatusUpdated < ::Subscriptions::BaseSubscription
        include Gitlab::Graphql::Laziness

        argument :pipeline_id, ::Types::GlobalIDType[::Ci::Pipeline],
          required: true,
          description: 'Global ID of the pipeline.'

        payload_type Types::Ci::PipelineType

        def authorized?(pipeline_id:)
          authorize_object_or_gid!(:read_pipeline, gid: pipeline_id)
        end
      end
    end
  end
end
