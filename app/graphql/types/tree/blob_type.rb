# frozen_string_literal: true
module Types
  module Tree
    class BlobType < BaseObject
      implements Types::Tree::EntryType

      present_using BlobPresenter

      graphql_name 'Blob'

      field :web_url, GraphQL::STRING_TYPE, null: true
      field :lfs_oid, GraphQL::STRING_TYPE, null: true, resolve: -> (blob, args, ctx) do
        Gitlab::Graphql::Loaders::BatchLfsOidLoader.new(blob.repository, blob.id).find
      end
    end
  end
end
