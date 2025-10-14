# frozen_string_literal: true

module Subscriptions
  module Ci
    module Jobs
      class JobProcessed < Subscriptions::BaseSubscription
        include Gitlab::Graphql::Laziness

        argument :project_id,
          ::Types::GlobalIDType[::Project],
          required: true,
          description: 'Global ID of the project.'

        argument :with_artifacts,
          GraphQL::Types::Boolean,
          required: false,
          description: 'Indicates if the job contains artifacts.'

        payload_type Types::Ci::JobType

        def authorized?(project_id:, **_kwargs)
          project = force(GitlabSchema.find_by_gid(project_id))

          unauthorized! unless project
          unauthorized! unless Ability.allowed?(current_user, :read_build, project)

          true
        end

        def update(project_id:, with_artifacts: false)
          processed_job = object

          return NO_UPDATE unless processed_job

          project = force(GitlabSchema.find_by_gid(project_id))

          return NO_UPDATE unless project && processed_job.project_id == project.id
          return NO_UPDATE unless Ability.allowed?(current_user, :read_build, processed_job)

          if processed_job.has_job_artifacts? && with_artifacts
            return processed_job
          elsif !processed_job.has_job_artifacts? && with_artifacts
            return NO_UPDATE
          end

          processed_job
        end
      end
    end
  end
end
