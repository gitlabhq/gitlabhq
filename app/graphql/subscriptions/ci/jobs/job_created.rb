# frozen_string_literal: true

module Subscriptions
  module Ci
    module Jobs
      class JobCreated < Subscriptions::BaseSubscription
        include Gitlab::Graphql::Laziness

        argument :project_id,
          ::Types::GlobalIDType[::Project],
          required: true,
          description: 'Global ID of the project.'

        payload_type Types::Ci::JobType

        def authorized?(project_id:)
          project = force(GitlabSchema.find_by_gid(project_id))

          unauthorized! unless project
          unauthorized! unless Ability.allowed?(current_user, :read_build, project)

          true
        end

        def update(project_id:)
          created_job = object

          return NO_UPDATE unless created_job

          project = force(GitlabSchema.find_by_gid(project_id))

          return NO_UPDATE unless project && created_job.project_id == project.id
          return NO_UPDATE unless Ability.allowed?(current_user, :read_build, created_job)

          created_job
        end
      end
    end
  end
end
