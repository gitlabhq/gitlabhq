# frozen_string_literal: true
module Types
  module Tree
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `Repository` that has its own authorization
    class TreeEntryType < BaseObject
      graphql_name 'TreeEntry'
      description 'Represents a directory'

      implements Types::Tree::EntryType
      present_using TreeEntryPresenter

      field :web_path, GraphQL::Types::String, null: true,
        description: 'Web path for the tree entry (directory).'
      field :web_url, GraphQL::Types::String, null: true,
        description: 'Web URL for the tree entry (directory).'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
