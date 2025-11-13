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

        argument :inputs, [::Types::Ci::Inputs::InputType],
          required: false,
          default_value: [],
          replace_null_with_default: true,
          description: 'Inputs to use when retrying the job.'

        authorize :retry_job

        def resolve(id:, variables:, inputs:)
          job = authorized_find!(id: id)
          project = job.project
          variables = variables.map(&:to_h)
          inputs = inputs.to_h { |input| [input[:name].to_sym, input[:value]] }

          if inputs.present? && !Feature.enabled?(:ci_job_inputs, project)
            return {
              job: nil,
              errors: ['The inputs argument is not available']
            }
          end

          response = ::Ci::RetryJobService.new(project, current_user).execute(job, variables: variables, inputs: inputs)

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
