# frozen_string_literal: true

module Mutations
  module Environments
    class Delete < ::Mutations::BaseMutation
      graphql_name 'EnvironmentDelete'
      description 'Delete an environment.'

      authorize :destroy_environment

      argument :id,
        ::Types::GlobalIDType[::Environment],
        required: true,
        description: 'Global ID of the environment to Delete.'

      def resolve(id:, **kwargs)
        environment = authorized_find!(id: id)

        response = ::Environments::DestroyService.new(environment.project, current_user, kwargs).execute(environment)

        if response.success?
          { errors: [] }
        else
          { errors: response.errors }
        end
      end
    end
  end
end
