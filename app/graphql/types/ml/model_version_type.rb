# frozen_string_literal: true

module Types
  module Ml
    # rubocop: disable Graphql/AuthorizeTypes -- authorization in ModelDetailsResolver
    class ModelVersionType < ::Types::BaseObject
      graphql_name 'MlModelVersion'
      description 'Version of a machine learning model'

      connection_type_class Types::LimitedCountableConnectionType

      markdown_field :description_html, null: true

      field :id, ::Types::GlobalIDType[::Ml::ModelVersion], null: false, description: 'ID of the model version.'

      field :created_at, Types::TimeType, null: false, description: 'Date of creation.'

      field :description, ::GraphQL::Types::String,
        null: true,
        description: 'Description of the version.'

      field :version, ::GraphQL::Types::String, null: false, description: 'Name of the version.'

      field :package_id, ::Types::GlobalIDType[::Packages::Package],
        null: false,
        description: 'Package for model version artifacts.'

      field :candidate, ::Types::Ml::CandidateType,
        null: false,
        description: 'Metrics, params and metadata for the model version.'

      field :_links, ::Types::Ml::ModelVersionLinksType, null: false, method: :itself,
        description: 'Map of links to perform actions on the model version.'
      def description_html_resolver
        ::MarkupHelper.markdown(object.description, context.to_h.dup)
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
