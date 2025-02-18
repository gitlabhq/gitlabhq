# frozen_string_literal: true

module Types
  module Ci
    module PipelineCreation
      # rubocop:disable Graphql/AuthorizeTypes -- Authorization is handled in the `ProjectType#ci_pipeline_creation_request` field
      class RequestType < BaseObject
        graphql_name 'CiPipelineCreationRequest'

        description 'Information about an asynchronous pipeline creation request'

        field :status, StatusEnum,
          null: false,
          description: 'Current status of the pipeline creation.'

        field :pipeline_id, GlobalIDType[::Ci::Pipeline],
          null: true,
          description: 'ID of the created pipeline if creation was successful.'

        field :error, GraphQL::Types::String,
          null: true,
          description: 'Error message if pipeline creation failed.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
