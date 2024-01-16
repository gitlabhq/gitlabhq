# frozen_string_literal: true

module Types
  module Ml
    # rubocop: disable Graphql/AuthorizeTypes -- authorization in ModelDetailsResolver
    class ModelLinksType < BaseObject
      graphql_name 'MLModelLinks'
      description 'Represents links to perform actions on the model'

      present_using ::Ml::ModelPresenter

      field :show_path, GraphQL::Types::String,
        null: true, description: 'Path to the details page of the model.', method: :path
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
