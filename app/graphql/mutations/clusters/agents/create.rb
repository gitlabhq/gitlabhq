# frozen_string_literal: true

module Mutations
  module Clusters
    module Agents
      class Create < BaseMutation
        graphql_name 'CreateClusterAgent'

        include FindsProject

        authorize :create_cluster

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Full path of the associated project for the cluster agent.'

        argument :name, GraphQL::Types::String,
          required: true,
          description: 'Name of the cluster agent.'

        field :cluster_agent,
          Types::Clusters::AgentType,
          null: true,
          description: 'Cluster agent created after mutation.'

        def resolve(project_path:, name:)
          project = authorized_find!(project_path)
          result = ::Clusters::Agents::CreateService.new(project, current_user, { name: name }).execute

          {
            cluster_agent: result[:cluster_agent],
            errors: Array.wrap(result[:message])
          }
        end
      end
    end
  end
end
