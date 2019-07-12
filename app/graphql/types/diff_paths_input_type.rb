# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class DiffPathsInputType < BaseInputObject
    argument :old_path, GraphQL::STRING_TYPE, required: false,
              description: 'The path of the file on the start sha'
    argument :new_path, GraphQL::STRING_TYPE, required: false,
              description: 'The path of the file on the head sha'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
