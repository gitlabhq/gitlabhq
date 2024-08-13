# frozen_string_literal: true

module API
  module Clusters
    class Agents < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :deployment_management
      urgency :low

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'List the agents for a project' do
          detail 'This feature was introduced in GitLab 14.10. Returns the list of agents registered for the project.'
          success Entities::Clusters::Agent
          tags %w[cluster_agents]
        end
        params do
          use :pagination
        end
        get ':id/cluster_agents' do
          not_found!('ClusterAgents') unless can?(current_user, :read_cluster_agent, user_project)

          agents = ::Clusters::AgentsFinder.new(user_project, current_user).execute

          present paginate(agents), with: Entities::Clusters::Agent
        end

        desc 'Get details about an agent' do
          detail 'This feature was introduced in GitLab 14.10. Gets a single agent details.'
          success Entities::Clusters::Agent
          tags %w[cluster_agents]
        end
        params do
          requires :agent_id, type: Integer, desc: 'The ID of an agent'
        end
        get ':id/cluster_agents/:agent_id' do
          agent = ::Clusters::AgentsFinder.new(user_project, current_user).find(params[:agent_id])

          present agent, with: Entities::Clusters::Agent
        end

        desc 'Register an agent with a project' do
          detail 'This feature was introduced in GitLab 14.10. Registers an agent to the project.'
          success Entities::Clusters::Agent
          tags %w[cluster_agents]
        end
        params do
          requires :name, type: String, desc: 'The name of the agent'
        end
        post ':id/cluster_agents' do
          authorize! :create_cluster, user_project

          params = declared_params(include_missing: false)

          result = ::Clusters::Agents::CreateService.new(user_project, current_user, { name: params[:name] }).execute

          bad_request!(result[:message]) if result[:status] == :error

          present result[:cluster_agent], with: Entities::Clusters::Agent
        end

        desc 'Delete a registered agent' do
          detail 'This feature was introduced in GitLab 14.10. Deletes an existing agent registration.'
          tags %w[cluster_agents]
        end
        params do
          requires :agent_id, type: Integer, desc: 'The ID of an agent'
        end
        delete ':id/cluster_agents/:agent_id' do
          authorize! :admin_cluster, user_project

          agent = ::Clusters::AgentsFinder.new(user_project, current_user).find(params[:agent_id])

          destroy_conditionally!(agent) do |agent|
            ::Clusters::Agents::DeleteService
              .new(container: agent.project, current_user: current_user, params: { cluster_agent: agent })
              .execute
          end
        end
      end
    end
  end
end
