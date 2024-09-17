# frozen_string_literal: true

module Types
  module Ml
    # rubocop: disable Graphql/AuthorizeTypes -- authorization in ModelDetailsResolver
    class ModelVersionLinksType < BaseObject
      graphql_name 'MLModelVersionLinks'
      description 'Represents links to perform actions on the model version'

      present_using ::Ml::ModelVersionPresenter

      field :show_path, GraphQL::Types::String,
        null: true, description: 'Path to the details page of the model version.', method: :path

      field :package_path, GraphQL::Types::String,
        null: true, description: 'Path to the package of the model version.'

      field :import_path, GraphQL::Types::String,
        null: true, description: 'File upload path for the machine learning model.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
