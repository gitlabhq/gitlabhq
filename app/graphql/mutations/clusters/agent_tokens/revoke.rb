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

          ::Clusters::AgentTokens::RevokeService.new(token: token, current_user: current_user).execute

          { errors: errors_on_object(token) }
        end
      end
    end
  end
end
