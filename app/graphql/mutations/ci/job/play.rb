# frozen_string_literal: true

module Mutations
  module Ci
    module Job
      class Play < Base
        graphql_name 'JobPlay'

        argument :id, ::Types::GlobalIDType[::Ci::Processable],
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
          description: 'Variables to use when playing a manual job.'

        argument :inputs, [::Types::Ci::Inputs::InputType],
          required: false,
          default_value: [],
          replace_null_with_default: true,
          description: 'Inputs to use when playing the job.'

        authorize :play_job

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

          result = job.play(current_user, variables, inputs)

          if result.error?
            return {
              job: nil,
              errors: [result.message]
            }
          end

          {
            job: result.payload[:job],
            errors: errors_on_object(result.payload[:job])
          }
        end
      end
    end
  end
end
