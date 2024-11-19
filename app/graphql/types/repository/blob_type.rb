# frozen_string_literal: true
module Types
  module Repository
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `Repository` that has its own authorization
    class BlobType < BaseObject
      graphql_name 'RepositoryBlob'

      present_using BlobPresenter

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

      field :fork_and_view_path, GraphQL::Types::String, null: true,
        description: 'Web path to view this blob using a forked project.'

      field :size, GraphQL::Types::BigInt, null: true,
        description: 'Size (in bytes) of the blob.'

      field :raw_size, GraphQL::Types::BigInt, null: true,
        description: 'Size (in bytes) of the blob, or the blob target if stored externally.'

      field :raw_blob, GraphQL::Types::String, null: true, method: :data,
        description: 'Raw content of the blob.'

      field :base64_encoded_blob, GraphQL::Types::String, null: true,
        experiment: { milestone: '17.1' }, description: 'Content of blob is encoded base64. Returns `null` if the `unicode_escaped_data` feature flag is disabled.'

      field :raw_text_blob, GraphQL::Types::String, null: true, method: :text_only_data,
        description: 'Raw content of the blob, if the blob is text data.'

      field :stored_externally, GraphQL::Types::Boolean, null: true, method: :stored_externally?,
        description: "Whether the blob's content is stored externally (for instance, in LFS)."

      field :external_storage, GraphQL::Types::String, null: true,
        description: "External storage being used, if enabled (for instance, 'LFS')."

      field :edit_blob_path, GraphQL::Types::String, null: true,
        description: 'Web path to edit the blob in the old-style editor.'

      field :raw_path, GraphQL::Types::String, null: true,
        description: 'Web path to download the raw blob.'

      field :external_storage_url, GraphQL::Types::String, null: true,
        description: 'Web path to download the raw blob via external storage, if enabled.'

      field :replace_path, GraphQL::Types::String, null: true,
        description: 'Web path to replace the blob content.'

      field :pipeline_editor_path, GraphQL::Types::String, null: true,
        description: 'Web path to edit .gitlab-ci.yml file.'

      field :gitpod_blob_url, GraphQL::Types::String, null: true,
        description: 'URL to the blob within Gitpod.'

      field :find_file_path, GraphQL::Types::String, null: true,
        description: 'Web path to find file.'

      field :blame_path, GraphQL::Types::String, null: true,
        description: 'Web path to blob blame page.'

      field :blame, Types::Blame::BlameType, null: true,
        description: 'Blob blame.', experiment: { milestone: '16.3' }, resolver: Resolvers::BlameResolver

      field :history_path, GraphQL::Types::String, null: true,
        description: 'Web path to blob history page.'

      field :permalink_path, GraphQL::Types::String, null: true,
        description: 'Web path to blob permalink.',
        calls_gitaly: true

      field :environment_formatted_external_url, GraphQL::Types::String, null: true,
        description: 'Environment on which the blob is available.',
        calls_gitaly: true

      field :environment_external_url_for_route_map, GraphQL::Types::String, null: true,
        description: 'Web path to blob on an environment.',
        calls_gitaly: true

      field :file_type, GraphQL::Types::String, null: true,
        description: 'Expected format of the blob based on the extension.'

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

      field :can_modify_blob_with_web_ide, GraphQL::Types::Boolean, null: false, method: :can_modify_blob_with_web_ide?,
        description: 'Whether the current user can modify the blob with Web IDE.'

      field :can_current_user_push_to_branch, GraphQL::Types::Boolean, null: true, method: :can_current_user_push_to_branch?,
        description: 'Whether the current user can push to the branch.'

      field :archived, GraphQL::Types::Boolean, null: true, method: :archived?,
        description: 'Whether the current project is archived.'

      field :language, GraphQL::Types::String,
        description: 'Blob language.',
        method: :blob_language,
        null: true,
        calls_gitaly: true

      field :code_navigation_path, GraphQL::Types::String, null: true, calls_gitaly: true,
        description: 'Web path for code navigation.'

      field :project_blob_path_root, GraphQL::Types::String, null: true,
        description: 'Web path for the root of the blob.'

      def raw_text_blob
        object.data unless object.binary?
      end

      def lfs_oid
        Gitlab::Graphql::Loaders::BatchLfsOidLoader.new(object.repository, object.id).find
      end
    end
  end
end

Types::Repository::BlobType.prepend_mod_with('Types::Repository::BlobType')
