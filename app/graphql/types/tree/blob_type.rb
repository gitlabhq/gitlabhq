# frozen_string_literal: true
module Types
  module Tree
    class BlobType < BaseObject
      implements Types::Tree::EntryType

      graphql_name 'Blob'
    end
  end
end
