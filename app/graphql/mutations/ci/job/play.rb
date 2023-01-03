# frozen_string_literal: true

module Mutations
  module Ci
    module Job
      class Play < Base
        graphql_name 'JobPlay'

        field :job,
              Types::Ci::JobType,
              null: true,
              description: 'Job after the mutation.'

        argument :variables, [::Types::Ci::VariableInputType],
                 required: false,
                 default_value: [],
                 replace_null_with_default: true,
                 description: 'Variables to use when playing a manual job.'

        authorize :update_build

        def resolve(id:, variables:)
          job = authorized_find!(id: id)
          project = job.project
          variables = variables.map(&:to_h)

          ::Ci::PlayBuildService.new(project, current_user).execute(job, variables)

          {
            job: job,
            errors: errors_on_object(job)
          }
        end
      end
    end
  end
end
