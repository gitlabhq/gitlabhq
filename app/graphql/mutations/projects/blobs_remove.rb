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

        begin
          project.set_repository_read_only!
          client = Gitlab::GitalyClient::CleanupService.new(project.repository)
          client.rewrite_history(blobs: blob_oids)

          audit_removals(project, blob_oids)

          { errors: [] }
        ensure
          project.set_repository_writable!
        end
      end

      private

      def audit_removals(project, blob_oids)
        context = {
          name: 'project_blobs_removal',
          author: current_user,
          scope: project,
          target: project,
          message: 'Project blobs removed',
          additional_details: { blob_oids: blob_oids }
        }

        ::Gitlab::Audit::Auditor.audit(context)
      end
    end
  end
end
