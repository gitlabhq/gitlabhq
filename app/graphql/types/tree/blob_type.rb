# frozen_string_literal: true
module Types
  module Tree
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `Repository` that has its own authorization
    class BlobType < BaseObject
      implements Types::Tree::EntryType

      present_using BlobPresenter

      graphql_name 'Blob'

      field :web_url, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
      field :lfs_oid, GraphQL::STRING_TYPE, null: true, resolve: -> (blob, args, ctx) do # rubocop:disable Graphql/Descriptions
        Gitlab::Graphql::Loaders::BatchLfsOidLoader.new(blob.repository, blob.id).find
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
