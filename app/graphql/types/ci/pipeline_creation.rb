# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes -- Authorization is done through the field
    class PipelineCreation < BaseObject
      graphql_name 'CiPipelineCreationType'

      field :status,
        ::Types::Ci::PipelineCreations::StatusEnum,
        null: true,
        description: 'Pipeline creation status.',
        alpha: { milestone: '17.4' }

      field :pipeline_id,
        GraphQL::Types::ID,
        null: true,
        description: 'ID of the created pipeline.',
        alpha: { milestone: '17.4' }
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
