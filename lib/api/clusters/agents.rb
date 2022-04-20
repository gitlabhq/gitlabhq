# frozen_string_literal: true

module API
  module Clusters
    class Agents < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :kubernetes_management

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'List agents' do
          detail 'This feature was introduced in GitLab 14.10.'
          success Entities::Clusters::Agent
        end
        params do
          use :pagination
        end
        get ':id/cluster_agents' do
          authorize! :read_cluster, user_project

          agents = ::Clusters::AgentsFinder.new(user_project, current_user).execute

          present paginate(agents), with: Entities::Clusters::Agent
        end

        desc 'Get single agent' do
          detail 'This feature was introduced in GitLab 14.10.'
          success Entities::Clusters::Agent
        end
        params do
          requires :agent_id, type: Integer, desc: 'The ID of an agent'
        end
        get ':id/cluster_agents/:agent_id' do
          authorize! :read_cluster, user_project

          agent = user_project.cluster_agents.find(params[:agent_id])

          present agent, with: Entities::Clusters::Agent
        end

        desc 'Add an agent to a project' do
          detail 'This feature was introduced in GitLab 14.10.'
          success Entities::Clusters::Agent
        end
        params do
          requires :name, type: String, desc: 'The name of the agent'
        end
        post ':id/cluster_agents' do
          authorize! :create_cluster, user_project

          params = declared_params(include_missing: false)

          result = ::Clusters::Agents::CreateService.new(user_project, current_user).execute(name: params[:name])

          bad_request!(result[:message]) if result[:status] == :error

          present result[:cluster_agent], with: Entities::Clusters::Agent
        end

        desc 'Delete an agent' do
          detail 'This feature was introduced in GitLab 14.10.'
        end
        params do
          requires :agent_id, type: Integer, desc: 'The ID of an agent'
        end
        delete ':id/cluster_agents/:agent_id' do
          authorize! :admin_cluster, user_project

          agent = user_project.cluster_agents.find(params.delete(:agent_id))

          destroy_conditionally!(agent)
        end
      end
    end
  end
end
