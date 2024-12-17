# frozen_string_literal: true

module Types
  module Ml
    # rubocop: disable Graphql/AuthorizeTypes -- authorization in ModelDetailsResolver
    class ModelType < ::Types::BaseObject
      graphql_name 'MlModel'
      description 'Machine learning model in the model registry'

      connection_type_class Types::LimitedCountableConnectionType

      present_using ::Ml::ModelPresenter

      markdown_field :description_html, null: true

      field :id, ::Types::GlobalIDType[::Ml::Model], null: false, description: 'ID of the model.'

      field :name, ::GraphQL::Types::String, null: false, description: 'Name of the model.'

      field :created_at, Types::TimeType, null: false, description: 'Date of creation.'

      field :author, ::Types::UserType, null: true, description: 'User that created the model.'

      field :description, ::GraphQL::Types::String,
        null: true,
        description: 'Description of the model.'

      field :latest_version, ::Types::Ml::ModelVersionType, null: true, description: 'Latest version of the model.'

      field :version_count, ::GraphQL::Types::Int, null: true, description: 'Count of versions in the model.'

      field :candidate_count, ::GraphQL::Types::Int,
        null: true,
        description: 'Count of candidates in the model.'

      field :_links, ::Types::Ml::ModelLinksType, null: false, method: :itself,
        description: 'Map of links to perform actions on the model.'

      field :versions, ::Types::Ml::ModelVersionType.connection_type, null: true,
        description: 'Versions of the model.',
        resolver: ::Resolvers::Ml::FindModelVersionsResolver

      field :candidates, ::Types::Ml::CandidateType.connection_type, null: true,
        description: 'Version candidates of the model.'

      field :default_experiment_path, ::GraphQL::Types::String,
        null: true,
        description: 'Path to default experiment page for the model.'

      field :version, ::Types::Ml::ModelVersionType, null: true,
        description: 'Version of the model.',
        resolver: ::Resolvers::Ml::FindModelVersionResolver
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
