# frozen_string_literal: true
module Types
  module Tree
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `Repository` that has its own authorization
    class SubmoduleType < BaseObject
      implements Types::Tree::EntryType

      graphql_name 'Submodule'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
