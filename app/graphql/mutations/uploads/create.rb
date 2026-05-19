# frozen_string_literal: true

module Mutations
  module Uploads
    class Create < BaseMutation
      graphql_name 'UploadCreate'
      description 'Creates an upload (uploads a file to a project or group for use in Markdown).'

      include Mutations::ResolvesResourceParent

      authorize :upload_file
      authorize_granular_token permissions: :create_markdown_upload,
        boundaries: [
          { boundary_argument: :project_path, boundary_type: :project },
          { boundary_argument: :group_path, boundary_type: :group }
        ]

      argument :file, ApolloUploadServer::Upload,
        required: true,
        description: 'File to upload.'

      field :upload, Types::UploadType,
        null: true,
        description: 'Uploaded file.'

      field :markdown, GraphQL::Types::String,
        null: true,
        description: 'Markdown-formatted link to the file.'

      field :url, GraphQL::Types::String,
        null: true,
        description: 'URL to access the file.'

      field :alt, GraphQL::Types::String,
        null: true,
        description: 'Alt text for the uploaded file. Usually the name of the file.'

      field :full_path, GraphQL::Types::String,
        null: true,
        description: 'Full path to the file.'

      def resolve(file:, **args)
        parent = authorized_resource_parent_find!(args)

        raise_resource_not_available_error! if parent.is_a?(Group) && Feature.disabled?(:group_uploads_api, parent)

        result = ::Uploads::CreateService.new(parent, current_user, file: file).execute

        result.payload.merge(errors: result.success? ? [] : [result.message])
      end
    end
  end
end
