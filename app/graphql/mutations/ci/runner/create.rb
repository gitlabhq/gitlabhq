# frozen_string_literal: true

module Mutations
  module Ci
    module Runner
      class Create < BaseMutation
        graphql_name 'RunnerCreate'

        authorize :create_runner

        include Mutations::Ci::Runner::CommonMutationArguments

        field :runner,
          Types::Ci::RunnerType,
          null: true,
          description: 'Runner after mutation.'

        def resolve(**args)
          if Feature.disabled?(:create_runner_workflow)
            raise Gitlab::Graphql::Errors::ResourceNotAvailable,
              '`create_runner_workflow` feature flag is disabled.'
          end

          create_runner(args)
        end

        private

        def create_runner(params)
          response = { runner: nil, errors: [] }
          result = ::Ci::Runners::CreateRunnerService.new(user: current_user, type: nil, params: params).execute

          if result.success?
            response[:runner] = result.payload[:runner]
          else
            response[:errors] = result.errors
          end

          response
        end
      end
    end
  end
end
