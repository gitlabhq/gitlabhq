# frozen_string_literal: true

module Mutations
  module Clusters
    module AgentTokens
      class Revoke < BaseMutation
        graphql_name 'ClusterAgentTokenRevoke'

        authorize :admin_cluster

        TokenID = ::Types::GlobalIDType[::Clusters::AgentToken]

        argument :id, TokenID,
                 required: true,
                 description: 'Global ID of the agent token that will be revoked.'

        def resolve(id:)
          token = authorized_find!(id: id)
          token.update(status: token.class.statuses[:revoked])

          { errors: errors_on_object(token) }
        end

        private

        def find_object(id:)
          # TODO: remove this line when the compatibility layer is removed
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
          id = TokenID.coerce_isolated_input(id)
          GitlabSchema.find_by_gid(id)
        end
      end
    end
  end
end
