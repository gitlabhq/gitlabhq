# frozen_string_literal: true

module API
  # Kubernetes Internal API
  module Internal
    class Kubernetes < ::API::Base
      include Gitlab::Utils::StrongMemoize

      before do
        check_feature_enabled
        authenticate_gitlab_kas_request!
      end

      helpers do
        def authenticate_gitlab_kas_request!
          render_api_error!('KAS JWT authentication invalid', 401) unless Gitlab::Kas.verify_api_request(headers)
        end

        def agent_token
          @agent_token ||= cluster_agent_token_from_authorization_token
        end

        def agent
          @agent ||= agent_token.agent
        end

        def repo_type
          Gitlab::GlRepository::PROJECT
        end

        def gitaly_info(project)
          shard = repo_type.repository_for(project).shard
          {
            address: Gitlab::GitalyClient.address(shard),
            token: Gitlab::GitalyClient.token(shard),
            features: Feature::Gitaly.server_feature_flags
          }
        end

        def gitaly_repository(project)
          {
            storage_name: project.repository_storage,
            relative_path: project.disk_path + '.git',
            gl_repository: repo_type.identifier_for_container(project),
            gl_project_path: repo_type.repository_for(project).full_path
          }
        end

        def check_feature_enabled
          not_found!('Internal API not found') unless Feature.enabled?(:kubernetes_agent_internal_api, type: :ops)
        end

        def check_agent_token
          unauthorized! unless agent_token

          ::Clusters::AgentTokens::TrackUsageService.new(agent_token).execute
        end

        def agent_has_access_to_project?(project)
          Guest.can?(:download_code, project) || agent.has_access_to?(project)
        end

        def increment_unique_events
          events = params[:unique_counters]&.slice(:agent_users_using_ci_tunnel)

          events&.each do |event, entity_ids|
            increment_unique_values(event, entity_ids)
          end
        end

        def increment_count_events
          events = params[:counters]&.slice(:gitops_sync, :k8s_api_proxy_request)

          Gitlab::UsageDataCounters::KubernetesAgentCounter.increment_event_counts(events)
        end

        def update_configuration(agent:, config:)
          ::Clusters::Agents::Authorizations::CiAccess::RefreshService.new(agent, config: config).execute
          ::Clusters::Agents::Authorizations::UserAccess::RefreshService.new(agent, config: config).execute
        end
      end

      namespace 'internal' do
        namespace 'kubernetes' do
          before do
            check_agent_token
          end

          desc 'Gets agent info' do
            detail 'Retrieves agent info for the given token'
          end
          route_setting :authentication, cluster_agent_token_allowed: true
          get '/agent_info', feature_category: :deployment_management, urgency: :low do
            project = agent.project

            status 200
            {
              project_id: project.id,
              agent_id: agent.id,
              agent_name: agent.name,
              gitaly_info: gitaly_info(project),
              gitaly_repository: gitaly_repository(project),
              default_branch: project.default_branch_or_main
            }
          end

          desc 'Gets project info' do
            detail 'Retrieves project info (if authorized)'
          end
          route_setting :authentication, cluster_agent_token_allowed: true
          get '/project_info', feature_category: :deployment_management, urgency: :low do
            project = find_project(params[:id])

            not_found! unless agent_has_access_to_project?(project)

            status 200
            {
              project_id: project.id,
              gitaly_info: gitaly_info(project),
              gitaly_repository: gitaly_repository(project),
              default_branch: project.default_branch_or_main
            }
          end
        end

        namespace 'kubernetes/agent_configuration' do
          desc 'POST agent configuration' do
            detail 'Store configuration for an agent'
          end
          params do
            requires :agent_id, type: Integer, desc: 'ID of the configured Agent'
            requires :agent_config, type: JSON, desc: 'Configuration for the Agent'
          end
          post '/', feature_category: :deployment_management, urgency: :low do
            agent = ::Clusters::Agent.find(params[:agent_id])
            update_configuration(agent: agent, config: params[:agent_config])

            no_content!
          end
        end

        namespace 'kubernetes/authorize_proxy_user' do
          desc 'Authorize a proxy user request'
          params do
            requires :agent_id, type: Integer, desc: 'ID of the agent accessed'
            requires :access_type, type: String, values: ['session_cookie'], desc: 'The type of the access key being verified.'
            requires :access_key, type: String, desc: 'The authentication secret for the given access type.'
            given access_type: ->(val) { val == 'session_cookie' } do
              requires :csrf_token, type: String, allow_blank: false, desc: 'CSRF token that must be checked when access_type is "session_cookie", to ensure the request originates from a GitLab browsing session.'
            end
          end
          post '/', feature_category: :deployment_management do
            # Load session
            public_session_id_string =
              begin
                Gitlab::Kas::UserAccess.decrypt_public_session_id(params[:access_key])
              rescue StandardError
                bad_request!('Invalid access_key')
              end

            session_id = Rack::Session::SessionId.new(public_session_id_string)
            session = ActiveSession.sessions_from_ids([session_id.private_id]).first
            unauthorized!('Invalid session') unless session

            # CSRF check
            unless ::Gitlab::Kas::UserAccess.valid_authenticity_token?(session.symbolize_keys, params[:csrf_token])
              unauthorized!('CSRF token does not match')
            end

            # Load user
            user = Warden::SessionSerializer.new('rack.session' => session).fetch(:user)
            unauthorized!('Invalid user in session') unless user

            # Load agent
            agent = ::Clusters::Agent.find(params[:agent_id])
            unauthorized!('Feature disabled for agent') unless ::Gitlab::Kas::UserAccess.enabled_for?(agent)

            service_response = ::Clusters::Agents::AuthorizeProxyUserService.new(user, agent).execute
            render_api_error!(service_response[:message], service_response[:reason]) unless service_response.success?

            service_response.payload
          end
        end

        namespace 'kubernetes/usage_metrics' do
          desc 'POST usage metrics' do
            detail 'Updates usage metrics for agent'
          end
          params do
            optional :counters, type: Hash do
              optional :gitops_sync, type: Integer, desc: 'The count to increment the gitops_sync metric by'
              optional :k8s_api_proxy_request, type: Integer, desc: 'The count to increment the k8s_api_proxy_request metric by'
            end

            optional :unique_counters, type: Hash do
              optional :agent_users_using_ci_tunnel, type: Array[Integer], desc: 'An array of user ids that have interacted with CI Tunnel'
            end
          end
          post '/', feature_category: :deployment_management do
            increment_count_events
            increment_unique_events

            no_content!
          rescue ArgumentError => e
            bad_request!(e.message)
          end
        end
      end
    end
  end
end

API::Internal::Kubernetes.prepend_mod_with('API::Internal::Kubernetes')
