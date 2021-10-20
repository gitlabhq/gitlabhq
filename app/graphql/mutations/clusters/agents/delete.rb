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
            .new(container: cluster_agent.project, current_user: current_user)
            .execute(cluster_agent)

          {
            errors: Array.wrap(result.message)
          }
        end

        private

        def find_object(id:)
          # TODO: remove this line when the compatibility layer is removed
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
          id = AgentID.coerce_isolated_input(id)
          GitlabSchema.find_by_gid(id)
        end
      end
    end
  end
end
