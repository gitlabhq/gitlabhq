# frozen_string_literal: true
module Types
  module Tree
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `Repository` that has its own authorization
    class TreeEntryType < BaseObject
      implements Types::Tree::EntryType

      present_using TreeEntryPresenter

      graphql_name 'TreeEntry'
      description 'Represents a directory'

      field :web_url, GraphQL::STRING_TYPE, null: true,
            description: 'Web URL for the tree entry (directory)'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
