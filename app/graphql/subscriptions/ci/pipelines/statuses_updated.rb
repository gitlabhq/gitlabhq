# frozen_string_literal: true

module Subscriptions
  module Ci
    module Pipelines
      class StatusesUpdated < ::Subscriptions::BaseSubscription
        include Gitlab::Graphql::Laziness

        argument :project_id,
          ::Types::GlobalIDType[::Project],
          required: true,
          description: 'Global ID of the project.'

        payload_type Types::Ci::PipelineType

        def authorized?(project_id:)
          authorize_object_or_gid!(:read_pipeline, gid: project_id)
        end

        def update(project_id:)
          updated_pipeline = object

          return NO_UPDATE unless updated_pipeline
          return NO_UPDATE unless updated_pipeline.project_id == project_id.model_id.to_i

          updated_pipeline
        end
      end
    end
  end
end
