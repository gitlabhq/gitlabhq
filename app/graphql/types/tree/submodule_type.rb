# frozen_string_literal: true
module Types
  module Tree
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `Repository` that has its own authorization
    class SubmoduleType < BaseObject
      implements Types::Tree::EntryType

      graphql_name 'Submodule'

      field :web_url, type: GraphQL::STRING_TYPE, null: true
      field :tree_url, type: GraphQL::STRING_TYPE, null: true
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
