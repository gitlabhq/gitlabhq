# frozen_string_literal: true
module Types
  module Tree
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `Repository` that has its own authorization
    class BlobType < BaseObject
      implements Types::Tree::EntryType

      present_using BlobPresenter

      graphql_name 'Blob'

      field :web_url, GraphQL::Types::String, null: true,
            description: 'Web URL of the blob.'
      field :web_path, GraphQL::Types::String, null: true,
            description: 'Web path of the blob.'
      field :lfs_oid, GraphQL::Types::String, null: true,
            calls_gitaly: true,
            description: 'LFS ID of the blob.'
      field :mode, GraphQL::Types::String, null: true,
            description: 'Blob mode in numeric format.'

      def lfs_oid
        Gitlab::Graphql::Loaders::BatchLfsOidLoader.new(object.repository, object.id).find
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
