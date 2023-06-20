# frozen_string_literal: true

module Mutations
  module Ci
    module JobArtifact
      class BulkDestroy < BaseMutation
        graphql_name 'BulkDestroyJobArtifacts'

        authorize :destroy_artifacts

        ArtifactId = ::Types::GlobalIDType[::Ci::JobArtifact]
        ProjectId = ::Types::GlobalIDType[::Project]

        argument :ids, [ArtifactId],
          required: true,
          description: 'Global IDs of the job artifacts to destroy.',
          prepare: ->(global_ids, _ctx) { GitlabSchema.parse_gids(global_ids, expected_type: ::Ci::JobArtifact) }

        argument :project_id, ProjectId,
          required: true,
          description: 'Global Project ID of the job artifacts to destroy. Incompatible with projectPath.'

        field :destroyed_count, ::GraphQL::Types::Int,
          null: true,
          description: 'Number of job artifacts deleted.'

        field :destroyed_ids, [ArtifactId],
          null: true,
          description: 'IDs of job artifacts that were deleted.'

        def find_object(id:)
          GlobalID::Locator.locate(id)
        end

        def resolve(**args)
          ids = args[:ids]
          project_id = args[:project_id]

          project = authorized_find!(id: project_id)

          raise Gitlab::Graphql::Errors::ArgumentError, 'IDs array of job artifacts can not be empty' if ids.empty?

          result = ::Ci::JobArtifacts::BulkDeleteByProjectService.new(
            job_artifact_ids: model_ids_of(ids),
            current_user: current_user,
            project: project
          ).execute

          if result.success?
            result.payload.slice(:destroyed_count, :destroyed_ids).merge(errors: [])
          else
            { errors: result.errors }
          end
        end

        private

        def model_ids_of(global_ids)
          global_ids.filter_map { |gid| gid.model_id.to_i }
        end
      end
    end
  end
end
