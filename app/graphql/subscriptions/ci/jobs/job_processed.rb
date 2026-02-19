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
          authorize_object_or_gid!(:read_build, gid: project_id)
        end

        def update(project_id:, with_artifacts: false)
          processed_job = object

          return NO_UPDATE unless processed_job && processed_job.project_id == project_id.model_id.to_i

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
