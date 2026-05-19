# frozen_string_literal: true

module Mutations
  module Ci
    module Runner
      class Delete < BaseMutation
        graphql_name 'RunnerDelete'

        authorize :delete_runner
        authorize_granular_token permissions: :delete_runner,
          boundaries: [
            { boundary_argument: :id, boundary_type: :project },
            { boundary_argument: :id, boundary_type: :group },
            { boundary: :instance, boundary_type: :instance }
          ]

        RunnerID = ::Types::GlobalIDType[::Ci::Runner]

        argument :id, RunnerID,
          required: true,
          description: 'ID of the runner to delete.'

        def resolve(id:, **runner_attrs)
          runner = authorized_find!(id: id)

          ::Ci::Runners::UnregisterRunnerService.new(runner, current_user).execute

          { errors: runner.errors.full_messages }
        end
      end
    end
  end
end
