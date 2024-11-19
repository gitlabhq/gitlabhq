# frozen_string_literal: true

module Types
  module Ml
    # rubocop: disable Graphql/AuthorizeTypes -- authorization in ModelDetailsResolver
    class ModelVersionType < ::Types::BaseObject
      graphql_name 'MlModelVersion'
      description 'Version of a machine learning model'
      present_using ::Ml::ModelVersionPresenter

      connection_type_class Types::LimitedCountableConnectionType

      markdown_field :description_html, null: true

      field :id, ::Types::GlobalIDType[::Ml::ModelVersion], null: false, description: 'ID of the model version.'

      field :created_at, Types::TimeType, null: false, description: 'Date of creation.'

      field :author, ::Types::UserType, null: true, description: 'User that created the model version.'

      field :description, ::GraphQL::Types::String,
        null: true,
        description: 'Description of the version.'

      field :artifacts_count, GraphQL::Types::Int, null: true, description: 'Number of files in the package.'

      field :version, ::GraphQL::Types::String, null: false, description: 'Name of the version.'

      field :package_id, ::Types::GlobalIDType[::Packages::Package],
        null: false,
        description: 'Package for model version artifacts.'

      field :candidate, ::Types::Ml::CandidateType,
        null: false,
        description: 'Metrics, params and metadata for the model version.'

      field :_links, ::Types::Ml::ModelVersionLinksType, null: false, method: :itself,
        description: 'Map of links to perform actions on the model version.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
