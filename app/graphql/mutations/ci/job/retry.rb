# frozen_string_literal: true

module Mutations
  module Ci
    module Job
      class Retry < Base
        graphql_name 'JobRetry'

        field :job,
              Types::Ci::JobType,
              null: true,
              description: 'Job after the mutation.'

        authorize :update_build

        def resolve(id:)
          job = authorized_find!(id: id)
          project = job.project

          response = ::Ci::RetryJobService.new(project, current_user).execute(job)

          if response.success?
            {
              job: response[:job],
              errors: []
            }
          else
            {
              job: nil,
              errors: [response.message]
            }
          end
        end
      end
    end
  end
end
