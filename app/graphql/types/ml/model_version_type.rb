# frozen_string_literal: true

module Types
  module Ml
    # rubocop: disable Graphql/AuthorizeTypes -- authorization in ModelDetailsResolver
    class ModelVersionType < ::Types::BaseObject
      graphql_name 'MlModelVersion'
      description 'Version of a machine learning model'

      connection_type_class Types::LimitedCountableConnectionType

      field :id, ::Types::GlobalIDType[::Ml::ModelVersion], null: false, description: 'ID of the model version.'

      field :created_at, Types::TimeType, null: false, description: 'Date of creation.'
      field :version, ::GraphQL::Types::String, null: false, description: 'Name of the version.'

      field :_links, ::Types::Ml::ModelVersionLinksType, null: false, method: :itself,
        description: 'Map of links to perform actions on the model version.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
