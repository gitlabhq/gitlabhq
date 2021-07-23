# frozen_string_literal: true

module Mutations
  module Environments
    module CanaryIngress
      class Update < ::Mutations::BaseMutation
        graphql_name 'EnvironmentsCanaryIngressUpdate'

        authorize :update_environment

        argument :id,
                 ::Types::GlobalIDType[::Environment],
                 required: true,
                 description: 'The global ID of the environment to update.'

        argument :weight,
                 GraphQL::Types::Int,
                 required: true,
                 description: 'The weight of the Canary Ingress.'

        def resolve(id:, **kwargs)
          environment = authorized_find!(id: id)

          result = ::Environments::CanaryIngress::UpdateService
            .new(environment.project, current_user, kwargs)
            .execute_async(environment)

          { errors: Array.wrap(result[:message]) }
        end

        def find_object(id:)
          # TODO: remove as part of https://gitlab.com/gitlab-org/gitlab/-/issues/257883
          id = ::Types::GlobalIDType[::Environment].coerce_isolated_input(id)
          GitlabSchema.find_by_gid(id)
        end
      end
    end
  end
end
