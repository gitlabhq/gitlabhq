# frozen_string_literal: true

module Mutations
  module Ci
    module Job
      class Retry < Base
        graphql_name 'JobRetry'

        field :job,
              Types::Ci::JobType,
              null: true,
              description: 'The job after the mutation.'

        authorize :update_build

        def resolve(id:)
          job = authorized_find!(id: id)
          project = job.project

          ::Ci::RetryBuildService.new(project, current_user).execute(job)
          {
            job: job,
            errors: errors_on_object(job)
          }
        end
      end
    end
  end
end
