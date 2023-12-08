# frozen_string_literal: true

module Types
  module Ml
    # rubocop: disable Graphql/AuthorizeTypes -- authorization in ModelDetailsResolver
    class ModelType < ::Types::BaseObject
      graphql_name 'MlModel'
      description 'Machine learning model in the model registry'

      field :id, ::Types::GlobalIDType[::Ml::Model], null: false, description: 'ID of the model.'

      field :name, ::GraphQL::Types::String, null: false, description: 'Name of the model.'

      field :versions, ::Types::Ml::ModelVersionType.connection_type, null: true,
        description: 'Versions of the model.'

      field :candidates, ::Types::Ml::CandidateType.connection_type, null: true,
        description: 'Version candidates of the model.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
