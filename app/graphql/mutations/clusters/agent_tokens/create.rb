# frozen_string_literal: true

module Mutations
  module Clusters
    module AgentTokens
      class Create < BaseMutation
        graphql_name 'ClusterAgentTokenCreate'

        authorize :create_cluster

        ClusterAgentID = ::Types::GlobalIDType[::Clusters::Agent]

        argument :cluster_agent_id,
                 ClusterAgentID,
                 required: true,
                 description: 'Global ID of the cluster agent that will be associated with the new token.'

        argument :description,
                 GraphQL::Types::String,
                 required: false,
                 description: 'Description of the token.'

        argument :name,
                 GraphQL::Types::String,
                 required: true,
                 description: 'Name of the token.'

        field :secret,
              GraphQL::Types::String,
              null: true,
              description: "Token secret value. Make sure you save it - you won't be able to access it again."

        field :token,
              Types::Clusters::AgentTokenType,
              null: true,
              description: 'Token created after mutation.'

        def resolve(args)
          cluster_agent = authorized_find!(id: args[:cluster_agent_id])

          result = ::Clusters::AgentTokens::CreateService
            .new(
              container: cluster_agent.project,
              current_user: current_user,
              params: args.merge(agent_id: cluster_agent.id)
            )
            .execute

          payload = result.payload

          {
           secret: payload[:secret],
           token: payload[:token],
           errors: Array.wrap(result.message)
          }
        end

        private

        def find_object(id:)
          # TODO: remove this line when the compatibility layer is removed
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
          id = ClusterAgentID.coerce_isolated_input(id)
          GitlabSchema.find_by_gid(id)
        end
      end
    end
  end
end
