# frozen_string_literal: true

module Mutations
  module Ci
    module Job
      class ArtifactsDestroy < Base
        graphql_name 'JobArtifactsDestroy'

        authorize :destroy_artifacts

        field :job,
          Types::Ci::JobType,
          null: true,
          description: 'Job with artifacts to be deleted.'

        field :destroyed_artifacts_count,
          GraphQL::Types::Int,
          null: false,
          description: 'Number of artifacts deleted.'

        def resolve(id:)
          job = authorized_find!(id: id)

          result = ::Ci::JobArtifacts::DeleteService.new(job).execute

          if result.success?
            {
              job: job,
              destroyed_artifacts_count: result.payload[:destroyed_artifacts_count],
              errors: Array(result.payload[:errors])
            }
          else
            {
              job: job,
              destroyed_artifacts_count: 0,
              errors: Array(result.message)
            }
          end
        end
      end
    end
  end
end
