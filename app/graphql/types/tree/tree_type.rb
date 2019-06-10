# frozen_string_literal: true
module Types
  module Tree
    class TreeType < BaseObject
      graphql_name 'Tree'

      field :trees, Types::Tree::TreeEntryType.connection_type, null: false, resolve: -> (obj, args, ctx) do
        Gitlab::Graphql::Representation::TreeEntry.decorate(obj.trees, obj.repository)
      end

      field :submodules, Types::Tree::SubmoduleType.connection_type, null: false

      field :blobs, Types::Tree::BlobType.connection_type, null: false, resolve: -> (obj, args, ctx) do
        Gitlab::Graphql::Representation::TreeEntry.decorate(obj.blobs, obj.repository)
      end
    end
  end
end
