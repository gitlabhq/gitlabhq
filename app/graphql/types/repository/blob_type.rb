# frozen_string_literal: true
module Types
  module Repository
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `Repository` that has its own authorization
    class BlobType < BaseObject
      present_using BlobPresenter

      graphql_name 'RepositoryBlob'

      field :id, GraphQL::ID_TYPE, null: false,
            description: 'ID of the blob.'

      field :oid, GraphQL::STRING_TYPE, null: false, method: :id,
            description: 'OID of the blob.'

      field :path, GraphQL::STRING_TYPE, null: false,
            description: 'Path of the blob.'

      field :name, GraphQL::STRING_TYPE,
            description: 'Blob name.',
            null: true

      field :mode, type: GraphQL::STRING_TYPE,
            description: 'Blob mode.',
            null: true

      field :lfs_oid, GraphQL::STRING_TYPE, null: true,
            calls_gitaly: true,
            description: 'LFS OID of the blob.'

      field :web_path, GraphQL::STRING_TYPE, null: true,
            description: 'Web path of the blob.'

      def lfs_oid
        Gitlab::Graphql::Loaders::BatchLfsOidLoader.new(object.repository, object.id).find
      end
    end
  end
end
