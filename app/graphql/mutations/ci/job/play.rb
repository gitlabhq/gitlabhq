# frozen_string_literal: true

module Mutations
  module Ci
    module Job
      class Play < Base
        graphql_name 'JobPlay'

        field :job,
              Types::Ci::JobType,
              null: true,
              description: 'The job after the mutation.'

        authorize :update_build

        def resolve(id:)
          job = authorized_find!(id: id)
          project = job.project

          ::Ci::PlayBuildService.new(project, current_user).execute(job)
          {
            job: job,
            errors: errors_on_object(job)
          }
        end
      end
    end
  end
end
