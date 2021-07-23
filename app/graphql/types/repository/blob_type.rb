# frozen_string_literal: true
module Types
  module Repository
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `Repository` that has its own authorization
    class BlobType < BaseObject
      present_using BlobPresenter

      graphql_name 'RepositoryBlob'

      field :id, GraphQL::Types::ID, null: false,
            description: 'ID of the blob.'

      field :oid, GraphQL::Types::String, null: false, method: :id,
            description: 'OID of the blob.'

      field :path, GraphQL::Types::String, null: false,
            description: 'Path of the blob.'

      field :name, GraphQL::Types::String,
            description: 'Blob name.',
            null: true

      field :mode, type: GraphQL::Types::String,
            description: 'Blob mode.',
            null: true

      field :lfs_oid, GraphQL::Types::String, null: true,
            calls_gitaly: true,
            description: 'LFS OID of the blob.'

      field :web_path, GraphQL::Types::String, null: true,
            description: 'Web path of the blob.'

      field :ide_edit_path, GraphQL::Types::String, null: true,
            description: 'Web path to edit this blob in the Web IDE.'

      field :fork_and_edit_path, GraphQL::Types::String, null: true,
            description: 'Web path to edit this blob using a forked project.'

      field :ide_fork_and_edit_path, GraphQL::Types::String, null: true,
            description: 'Web path to edit this blob in the Web IDE using a forked project.'

      field :size, GraphQL::Types::Int, null: true,
            description: 'Size (in bytes) of the blob.'

      field :raw_size, GraphQL::Types::Int, null: true,
            description: 'Size (in bytes) of the blob, or the blob target if stored externally.'

      field :raw_blob, GraphQL::Types::String, null: true, method: :data,
            description: 'The raw content of the blob.'

      field :raw_text_blob, GraphQL::Types::String, null: true, method: :text_only_data,
            description: 'The raw content of the blob, if the blob is text data.'

      field :stored_externally, GraphQL::Types::Boolean, null: true, method: :stored_externally?,
            description: "Whether the blob's content is stored externally (for instance, in LFS)."

      field :edit_blob_path, GraphQL::Types::String, null: true,
            description: 'Web path to edit the blob in the old-style editor.'

      field :raw_path, GraphQL::Types::String, null: true,
            description: 'Web path to download the raw blob.'

      field :external_storage_url, GraphQL::Types::String, null: true,
            description: 'Web path to download the raw blob via external storage, if enabled.'

      field :replace_path, GraphQL::Types::String, null: true,
            description: 'Web path to replace the blob content.'

      field :file_type, GraphQL::Types::String, null: true,
            description: 'The expected format of the blob based on the extension.'

      field :simple_viewer, type: Types::BlobViewerType,
            description: 'Blob content simple viewer.',
            null: false

      field :rich_viewer, type: Types::BlobViewerType,
            description: 'Blob content rich viewer.',
            null: true

      field :plain_data, GraphQL::Types::String,
            description: 'Blob plain highlighted data.',
            null: true,
            calls_gitaly: true

      field :can_modify_blob, GraphQL::Types::Boolean, null: true, method: :can_modify_blob?,
            calls_gitaly: true,
            description: 'Whether the current user can modify the blob.'

      def raw_text_blob
        object.data unless object.binary?
      end

      def lfs_oid
        Gitlab::Graphql::Loaders::BatchLfsOidLoader.new(object.repository, object.id).find
      end
    end
  end
end
