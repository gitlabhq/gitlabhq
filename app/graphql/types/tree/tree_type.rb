# frozen_string_literal: true
module Types
  module Tree
    class TreeType < BaseObject
      graphql_name 'Tree'

      field :trees, Types::Tree::TreeEntryType.connection_type, null: false
      field :submodules, Types::Tree::SubmoduleType.connection_type, null: false
      field :blobs, Types::Tree::BlobType.connection_type, null: false
    end
  end
end
