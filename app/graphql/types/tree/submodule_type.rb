# frozen_string_literal: true
module Types
  module Tree
    class SubmoduleType < BaseObject
      implements Types::Tree::EntryType

      graphql_name 'Submodule'
    end
  end
end
