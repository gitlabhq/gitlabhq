# frozen_string_literal: true
module Types
  module Tree
    class TreeEntryType < BaseObject
      implements Types::Tree::EntryType

      present_using TreeEntryPresenter

      graphql_name 'TreeEntry'
      description 'Represents a directory'

      field :web_url, GraphQL::STRING_TYPE, null: true
    end
  end
end
