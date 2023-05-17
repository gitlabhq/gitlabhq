# frozen_string_literal: true

module Mutations
  module Environments
    class Stop < ::Mutations::BaseMutation
      graphql_name 'EnvironmentStop'
      description 'Stop an environment.'

      authorize :stop_environment

      argument :id,
        ::Types::GlobalIDType[::Environment],
        required: true,
        description: 'Global ID of the environment to stop.'

      argument :force,
        GraphQL::Types::Boolean,
        required: false,
        description: 'Force environment to stop without executing on_stop actions.'

      field :environment,
        Types::EnvironmentType,
        null: true,
        description: 'Environment after attempt to stop.'

      def resolve(id:, **kwargs)
        environment = authorized_find!(id: id)

        response = ::Environments::StopService.new(environment.project, current_user, kwargs).execute(environment)

        if response.success?
          { environment: response.payload[:environment], errors: [] }
        else
          { environment: response.payload[:environment], errors: response.errors }
        end
      end
    end
  end
end
