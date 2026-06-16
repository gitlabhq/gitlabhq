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
        desc 'List all agents' do
          detail 'Lists all agents registered for the project. You must have the Developer, Maintainer, or Owner ' \
            'role to use this endpoint.'
          success Entities::Clusters::Agent
          tags %w[cluster_agents]
        end
        params do
          use :pagination
        end
        route_setting :authorization, permissions: :read_cluster_agent, boundary_type: :project
        get ':id/cluster_agents' do
          not_found!('ClusterAgents') unless can?(current_user, :read_cluster_agent, user_project)

          agents = ::Clusters::AgentsFinder.new(user_project, current_user).execute

          present paginate(agents), with: Entities::Clusters::Agent
        end

        desc 'Retrieve details on an agent' do
          detail 'Retrieves details on a specified agent. You must have the Developer, Maintainer, or Owner role to ' \
            'use this endpoint.'
          success Entities::Clusters::Agent
          tags %w[cluster_agents]
        end
        params do
          requires :agent_id, type: Integer, desc: 'The ID of an agent'
        end
        route_setting :authorization, permissions: :read_cluster_agent, boundary_type: :project
        get ':id/cluster_agents/:agent_id' do
          agent = ::Clusters::AgentsFinder.new(user_project, current_user).find(params[:agent_id])

          present agent, with: Entities::Clusters::Agent
        end

        desc 'Create an agent' do
          detail 'Creates an agent for the project. You must have the Maintainer or Owner role to use this endpoint.'
          success Entities::Clusters::Agent
          tags %w[cluster_agents]
        end
        params do
          requires :name, type: String, desc: 'The name of the agent'
        end
        route_setting :authorization, permissions: :create_cluster_agent, boundary_type: :project
        post ':id/cluster_agents' do
          authorize! :create_cluster, user_project

          params = declared_params(include_missing: false)

          result = ::Clusters::Agents::CreateService.new(user_project, current_user, { name: params[:name] }).execute

          bad_request!(result[:message]) if result[:status] == :error

          present result[:cluster_agent], with: Entities::Clusters::Agent
        end

        desc 'Delete an agent' do
          detail 'Deletes an existing agent registration. You must have the Maintainer or Owner role to use this ' \
            'endpoint.'
          success code: 204, message: 'Resource deleted'
          tags %w[cluster_agents]
        end
        params do
          requires :agent_id, type: Integer, desc: 'The ID of an agent'
        end
        route_setting :authorization, permissions: :delete_cluster_agent, boundary_type: :project
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
