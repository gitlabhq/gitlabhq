# frozen_string_literal: true

module Mutations
  module Environments
    class Update < ::Mutations::BaseMutation
      graphql_name 'EnvironmentUpdate'
      description 'Update an environment.'

      authorize :update_environment

      argument :id,
        ::Types::GlobalIDType[::Environment],
        required: true,
        description: 'Global ID of the environment to update.'

      argument :external_url,
        GraphQL::Types::String,
        required: false,
        description: 'External URL of the environment.'

      argument :tier,
        Types::DeploymentTierEnum,
        required: false,
        description: 'Tier of the environment.'

      field :environment,
        Types::EnvironmentType,
        null: true,
        description: 'Environment after attempt to update.'

      def resolve(id:, **kwargs)
        environment = authorized_find!(id: id)

        response = ::Environments::UpdateService.new(environment.project, current_user, kwargs).execute(environment)

        if response.success?
          { environment: response.payload[:environment], errors: [] }
        else
          { environment: response.payload[:environment], errors: response.errors }
        end
      end
    end
  end
end
