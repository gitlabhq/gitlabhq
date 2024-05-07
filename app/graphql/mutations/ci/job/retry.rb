# frozen_string_literal: true

module Mutations
  module Ci
    module Job
      class Retry < Base
        graphql_name 'JobRetry'

        JobID = ::Types::GlobalIDType[::Ci::Processable]

        argument :id, JobID,
          required: true,
          description: 'ID of the job to mutate.'

        field :job,
          Types::Ci::JobType,
          null: true,
          description: 'Job after the mutation.'

        argument :variables, [::Types::Ci::VariableInputType],
          required: false,
          default_value: [],
          replace_null_with_default: true,
          description: 'Variables to use when retrying a manual job.'

        authorize :update_build

        def resolve(id:, variables:)
          job = authorized_find!(id: id)
          project = job.project
          variables = variables.map(&:to_h)

          response = ::Ci::RetryJobService.new(project, current_user).execute(job, variables: variables)

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
