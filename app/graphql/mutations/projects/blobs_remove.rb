# frozen_string_literal: true

module Mutations
  module Projects
    class BlobsRemove < BaseMutation
      graphql_name 'projectBlobsRemove'

      include FindsProject

      EMPTY_BLOBS_OIDS_ARG = <<~ERROR
        Argument 'blobOids' on InputObject 'projectBlobsRemoveInput' is required. Expected type [String!]!
      ERROR

      authorize :owner_access

      argument :project_path, GraphQL::Types::ID,
        required: true,
        description: 'Full path of the project to replace.'

      argument :blob_oids, [GraphQL::Types::String],
        required: true,
        description: 'List of blob oids.',
        prepare: ->(blob_oids, _ctx) do
          blob_oids.reject!(&:blank?)

          break blob_oids if blob_oids.present?

          raise GraphQL::ExecutionError, EMPTY_BLOBS_OIDS_ARG
        end

      def resolve(project_path:, blob_oids:)
        project = authorized_find!(project_path)

        result = ::Repositories::RewriteHistoryService.new(project, current_user).async_execute(blob_oids: blob_oids)

        return { errors: result.errors } if result.error?

        { errors: [] }
      end
    end
  end
end
