# frozen_string_literal: true

module Mutations
  module Clusters
    module Agents
      class Delete < BaseMutation
        graphql_name 'ClusterAgentDelete'

        authorize :admin_cluster

        AgentID = ::Types::GlobalIDType[::Clusters::Agent]

        argument :id, AgentID,
          required: true,
          description: 'Global ID of the cluster agent that will be deleted.'

        def resolve(id:)
          cluster_agent = authorized_find!(id: id)
          result = ::Clusters::Agents::DeleteService
            .new(container: cluster_agent.project, current_user: current_user, params: { cluster_agent: cluster_agent })
            .execute

          {
            errors: Array.wrap(result.message)
          }
        end
      end
    end
  end
end
