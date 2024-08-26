# frozen_string_literal: true

module API
  module Clusters
    class AgentUrlConfigurations < ::API::Base
      before do
        authenticate!

        not_found! unless ::Gitlab::CurrentSettings.receptive_cluster_agents_enabled
      end

      feature_category :deployment_management

      helpers do
        def find_url_configuration(agent)
          cfg = agent.agent_url_configuration

          return unless cfg

          # NOTE: we currently only support a single url configuration for an agent.
          # However, this will change in future iterations when we want to support at least 2.
          return unless cfg.id == params[:url_configuration_id]

          cfg
        end
      end

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        params do
          requires :agent_id, type: Integer, desc: 'The ID of an agent'
        end
        resource ':id/cluster_agents/:agent_id' do
          resource :url_configurations do
            desc 'List agent url configurations' do
              detail 'This feature was introduced in GitLab 17.4. List agent url configurations'
              success Entities::Clusters::AgentUrlConfiguration
              tags %w[cluster_agents]
            end
            get do
              authorize! :admin_cluster, user_project

              agent = ::Clusters::AgentsFinder.new(user_project, current_user).find(params[:agent_id])

              not_found! unless agent

              url_cfg = agent.agent_url_configuration

              if url_cfg
                present [url_cfg], with: Entities::Clusters::AgentUrlConfiguration
              else
                []
              end
            end

            desc 'Get a single agent url configuration' do
              detail 'This feature was introduced in GitLab 17.4. Gets a single agent url configuration.'
              success Entities::Clusters::AgentUrlConfiguration
              tags %w[cluster_agents]
            end
            params do
              requires :url_configuration_id, type: Integer, desc: 'The ID of the agent url configuration'
            end
            get ':url_configuration_id' do
              authorize! :admin_cluster, user_project

              agent = ::Clusters::AgentsFinder.new(user_project, current_user).find(params[:agent_id])

              not_found! unless agent

              url_cfg = find_url_configuration(agent)

              not_found! unless url_cfg

              present url_cfg, with: Entities::Clusters::AgentUrlConfiguration
            end

            desc 'Create an agent url configuration for a receptive agent' do
              detail 'This feature was introduced in GitLab 17.4. ' \
                'Creates a new url configuration for a receptive agent.'
              success Entities::Clusters::AgentUrlConfiguration
              tags %w[cluster_agents]
            end
            params do
              requires :url, type: String, desc: 'The url where the receptive agent is listening'
              optional :client_cert, type: String, desc: 'The base64-encoded client certificate in PEM format for mTLS'
              optional :client_key, type: String, desc: 'The base64-encoded client key in PEM format for mTLS'
              optional :ca_cert, type: String,
                desc: 'The base64-encoded ca certificate in PEM format for TLS validation'
              optional :tls_host, type: String, desc: 'The host name for TLS validation'
            end
            post do
              authorize! :create_cluster, user_project

              agent = ::Clusters::AgentsFinder.new(user_project, current_user).find(params[:agent_id])

              not_found! unless agent

              url_cfg_params = declared_params(include_missing: false)

              url_cfg_params[:ca_cert] = Base64.decode64(url_cfg_params[:ca_cert]) if url_cfg_params[:ca_cert]
              if url_cfg_params[:client_cert]
                url_cfg_params[:client_cert] =
                  Base64.decode64(url_cfg_params[:client_cert])
              end

              url_cfg_params[:client_key] = Base64.decode64(url_cfg_params[:client_key]) if url_cfg_params[:client_key]

              result = ::Clusters::Agents::CreateUrlConfigurationService.new(
                agent: agent,
                current_user: current_user,
                params: url_cfg_params
              ).execute

              bad_request!(result[:message]) if result[:status] == :error

              present result[:url_configuration], with: Entities::Clusters::AgentUrlConfiguration
            end

            desc 'Delete an agent url configuration' do
              detail 'This feature was introduced in GitLab 17.4. Deletes an agent url configuration.'
              tags %w[cluster_agents]
            end
            params do
              requires :url_configuration_id, type: Integer, desc: 'The ID of the agent url configuration'
            end
            delete ':url_configuration_id' do
              authorize! :admin_cluster, user_project

              agent = ::Clusters::AgentsFinder.new(user_project, current_user).find(params[:agent_id])

              not_found! unless agent

              url_cfg = find_url_configuration(agent)

              not_found! unless url_cfg

              destroy_conditionally!(url_cfg) do |url_cfg|
                ::Clusters::Agents::DeleteUrlConfigurationService
                  .new(agent: agent, current_user: current_user, url_configuration: url_cfg)
                  .execute
              end
            end
          end
        end
      end
    end
  end
end
