# frozen_string_literal: true

module Types
  module Ci
    module PipelineCreation
      # rubocop:disable Graphql/AuthorizeTypes -- Authorization is handled in the `ProjectType#ci_pipeline_creation_request` field
      class RequestType < BaseObject
        graphql_name 'CiPipelineCreationRequest'

        description 'Information about an asynchronous pipeline creation request'

        field :id, GraphQL::Types::String,
          null: true,
          description: 'Unique ID of the pipeline creation request.'

        field :status, StatusEnum,
          null: false,
          description: 'Current status of the pipeline creation.'

        field :user_initiated, GraphQL::Types::Boolean,
          null: false,
          description: 'Indicates whether the pipeline creation was explicitly requested by a user.'

        field :pipeline_id, GlobalIDType[::Ci::Pipeline],
          null: true,
          description: 'ID of the created pipeline if creation was successful.'

        field :error, GraphQL::Types::String,
          null: true,
          description: 'Error message if pipeline creation failed.'

        field :pipeline, Types::Ci::PipelineType,
          null: true,
          description: 'Pipeline object created by the request.'

        def pipeline
          return unless object['pipeline_id']

          ::Gitlab::Graphql::Loaders::BatchModelLoader.new(::Ci::Pipeline, object['pipeline_id']).find
        end

        # Entries written before this flag existed lack it; treat them as
        # user-initiated so a genuine failure is never hidden.
        def user_initiated
          object['user_initiated'] != false
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
