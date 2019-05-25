# frozen_string_literal: true
module Types
  module Tree
    class TreeEntryType < BaseObject
      implements Types::Tree::EntryType

      graphql_name 'TreeEntry'
      description 'Represents a directory'
    end
  end
end
