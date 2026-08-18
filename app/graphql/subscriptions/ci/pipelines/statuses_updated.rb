# frozen_string_literal: true

module Subscriptions
  module Ci
    module Pipelines
      class StatusesUpdated < ::Subscriptions::BaseSubscription
        include Gitlab::Graphql::Laziness

        argument :project_id,
          ::Types::GlobalIDType[::Project],
          required: false,
          description: 'Global ID of the project.'

        argument :project_full_path, GraphQL::Types::ID, # rubocop:disable Graphql/IDType -- This is a project full path, not a generic id.
          required: false,
          description: 'Full path of the project.'

        argument :sha,
          GraphQL::Types::String,
          required: false,
          description: 'Filter updates to pipelines run for the given commit SHA.'

        validates exactly_one_of: [:project_id, :project_full_path]

        payload_type Types::Ci::PipelineType

        def authorized?(project_id: nil, project_full_path: nil, **_kwargs)
          return authorize_object_or_gid!(:read_pipeline, gid: project_id) if project_id

          auth_object = object.presence || Project.find_by_full_path(project_full_path)

          return unauthorized! if auth_object.nil?

          unauthorized! unless Ability.allowed?(current_user, :read_pipeline, auth_object)

          true
        end

        def update(project_id: nil, project_full_path: nil, sha: nil)
          updated_pipeline = object

          return NO_UPDATE unless updated_pipeline
          return NO_UPDATE unless subscribed_project?(updated_pipeline, project_id, project_full_path)
          return NO_UPDATE unless sha.nil? || updated_pipeline.sha == sha

          updated_pipeline
        end

        private

        def subscribed_project?(pipeline, project_id, project_full_path)
          if project_id
            pipeline.project_id == project_id.model_id.to_i
          else
            pipeline.project.full_path == project_full_path
          end
        end
      end
    end
  end
end
