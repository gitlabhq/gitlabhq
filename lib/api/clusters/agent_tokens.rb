# frozen_string_literal: true

module API
  module Clusters
    class AgentTokens < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :deployment_management

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        params do
          requires :agent_id, type: Integer, desc: 'The ID of an agent'
        end
        resource ':id/cluster_agents/:agent_id' do
          resource :tokens do
            desc 'List tokens for an agent' do
              detail 'This feature was introduced in GitLab 15.0. Returns a list of tokens for an agent.'
              success Entities::Clusters::AgentTokenBasic
              tags %w[cluster_agents]
            end
            params do
              use :pagination
            end
            get do
              agent = ::Clusters::AgentsFinder.new(user_project, current_user).find(params[:agent_id])
              agent_tokens = ::Clusters::AgentTokensFinder.new(agent, current_user, status: :active).execute

              present paginate(agent_tokens), with: Entities::Clusters::AgentTokenBasic
            end

            desc 'Get a single agent token' do
              detail 'This feature was introduced in GitLab 15.0. Gets a single agent token.'
              success Entities::Clusters::AgentToken
              tags %w[cluster_agents]
            end
            params do
              requires :token_id, type: Integer, desc: 'The ID of the agent token'
            end
            get ':token_id' do
              agent = ::Clusters::AgentsFinder.new(user_project, current_user).find(params[:agent_id])
              token = ::Clusters::AgentTokensFinder.new(agent, current_user, status: :active).find(params[:token_id])

              present token, with: Entities::Clusters::AgentToken
            end

            desc 'Create an agent token' do
              detail 'This feature was introduced in GitLab 15.0. Creates a new token for an agent.'
              success Entities::Clusters::AgentTokenWithToken
              tags %w[cluster_agents]
            end
            params do
              requires :name, type: String, desc: 'The name for the token'
              optional :description, type: String, desc: 'The description for the token'
            end
            post do
              authorize! :create_cluster, user_project

              token_params = declared_params(include_missing: false)

              agent = ::Clusters::AgentsFinder.new(user_project, current_user).find(params[:agent_id])

              result = ::Clusters::AgentTokens::CreateService.new(
                agent: agent,
                current_user: current_user,
                params: token_params
              ).execute

              bad_request!(result[:message]) if result[:status] == :error

              present result[:token], with: Entities::Clusters::AgentTokenWithToken
            end

            desc 'Revoke an agent token' do
              detail 'This feature was introduced in GitLab 15.0. Revokes an agent token.'
              tags %w[cluster_agents]
            end
            params do
              requires :token_id, type: Integer, desc: 'The ID of the agent token'
            end
            delete ':token_id' do
              authorize! :admin_cluster, user_project

              agent = ::Clusters::AgentsFinder.new(user_project, current_user).find(params[:agent_id])
              token = ::Clusters::AgentTokensFinder.new(agent, current_user).find(params[:token_id])

              result = ::Clusters::AgentTokens::RevokeService.new(token: token, current_user: current_user).execute

              bad_request!(result[:message]) if result[:status] == :error

              status :no_content
            end
          end
        end
      end
    end
  end
end
