# frozen_string_literal: true

module Types
  module Ml
    # rubocop: disable Graphql/AuthorizeTypes -- authorization in ModelDetailsResolver
    class ModelType < ::Types::BaseObject
      graphql_name 'MlModel'
      description 'Machine learning model in the model registry'

      connection_type_class Types::LimitedCountableConnectionType

      field :id, ::Types::GlobalIDType[::Ml::Model], null: false, description: 'ID of the model.'

      field :name, ::GraphQL::Types::String, null: false, description: 'Name of the model.'

      field :created_at, Types::TimeType, null: false, description: 'Date of creation.'

      field :latest_version, ::Types::Ml::ModelVersionType, null: true, description: 'Latest version of the model.'

      field :version_count, ::GraphQL::Types::Int, null: true, description: 'Count of versions in the model.'

      field :_links, ::Types::Ml::ModelLinksType, null: false, method: :itself,
        description: 'Map of links to perform actions on the model.'

      field :versions, ::Types::Ml::ModelVersionType.connection_type, null: true,
        description: 'Versions of the model.'

      field :candidates, ::Types::Ml::CandidateType.connection_type, null: true,
        description: 'Version candidates of the model.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
