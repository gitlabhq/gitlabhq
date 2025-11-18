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
          project = force(GitlabSchema.find_by_gid(project_id))

          unauthorized! unless project
          unauthorized! unless Ability.allowed?(current_user, :read_pipeline, project)

          true
        end

        def update(project_id:)
          updated_pipeline = object

          return NO_UPDATE unless updated_pipeline

          project = force(GitlabSchema.find_by_gid(project_id))

          return NO_UPDATE unless project && updated_pipeline.project_id == project.id
          return NO_UPDATE unless Ability.allowed?(current_user, :read_pipeline, updated_pipeline)

          updated_pipeline
        end
      end
    end
  end
end
