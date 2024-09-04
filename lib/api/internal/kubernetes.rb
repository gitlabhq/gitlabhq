# frozen_string_literal: true

module API
  # Kubernetes Internal API
  module Internal
    class Kubernetes < ::API::Base
      before do
        authenticate_gitlab_kas_request!
      end

      helpers ::API::Helpers::KasHelpers
      helpers ::API::Helpers::Kubernetes::AgentHelpers

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

          desc 'Verify agent access to a project' do
            detail 'Verifies if the agent (owning the token) is authorized to access the given project'
          end
          route_setting :authentication, cluster_agent_token_allowed: true
          get '/verify_project_access', feature_category: :deployment_management, urgency: :low do
            project = find_project(params[:id])

            not_found! unless agent_has_access_to_project?(project)

            status 204
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
            requires :access_type, type: String, values: %w[session_cookie personal_access_token], desc: 'The type of access key being verified.'
            requires :access_key, type: String, desc: 'The authentication secret for the given access type.'
            given access_type: ->(val) { val == 'session_cookie' } do
              requires :csrf_token, type: String, allow_blank: false, desc: 'CSRF token that must be checked when access_type is "session_cookie", to ensure the request originates from a GitLab browsing session.'
            end
          end
          post '/', feature_category: :deployment_management do
            # Load user
            user = if params[:access_type] == 'session_cookie'
                     retrieve_user_from_session_cookie
                   elsif params[:access_type] == 'personal_access_token'
                     retrieve_user_from_personal_access_token
                   end

            bad_request!('Unable to get user from request data') if user.nil?

            # Load agent
            agent = ::Clusters::Agent.find(params[:agent_id])
            unauthorized!('Feature disabled for agent') unless ::Gitlab::Kas::UserAccess.enabled?

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
              optional :k8s_api_proxy_request, type: Integer, desc: 'The count to increment the k8s_api_proxy_request metric by'
              optional :flux_git_push_notifications_total, type: Integer, desc: 'The count to increment the flux_git_push_notifications_total metrics by'
              optional :k8s_api_proxy_requests_via_ci_access, type: Integer, desc: 'The count to increment the k8s_api_proxy_requests_via_ci_access metric by'
              optional :k8s_api_proxy_requests_via_user_access, type: Integer, desc: 'The count to increment the k8s_api_proxy_requests_via_user_access metric by'
              optional :k8s_api_proxy_requests_via_pat_access, type: Integer, desc: 'The count to increment the k8s_api_proxy_requests_via_pat_access metric by'
            end

            optional :unique_counters, type: Hash do
              optional :k8s_api_proxy_requests_unique_users_via_ci_access, type: Array[Integer], desc: 'An array of users that have interacted with the CI tunnel via `ci_access`'
              optional :k8s_api_proxy_requests_unique_agents_via_ci_access, type: Array[Integer], desc: 'An array of agents that have interacted with the CI tunnel via `ci_access`'
              optional :k8s_api_proxy_requests_unique_users_via_user_access, type: Array[Integer], desc: 'An array of users that have interacted with the CI tunnel via `user_access`'
              optional :k8s_api_proxy_requests_unique_agents_via_user_access, type: Array[Integer], desc: 'An array of agents that have interacted with the CI tunnel via `user_access`'
              optional :k8s_api_proxy_requests_unique_users_via_pat_access, type: Array[Integer], desc: 'An array of users that have interacted with the CI tunnel via personal access token'
              optional :k8s_api_proxy_requests_unique_agents_via_pat_access, type: Array[Integer], desc: 'An array of agents that have interacted with the CI tunnel via personal access token'
              optional :flux_git_push_notified_unique_projects, type: Array[Integer], desc: 'An array of projects that have been notified to reconcile their Flux workloads'
            end
          end
          post '/', feature_category: :deployment_management do
            increment_count_events
            increment_unique_events
            track_unique_user_events

            no_content!
          rescue ArgumentError => e
            bad_request!(e.message)
          end
        end

        namespace 'kubernetes/agent_events' do
          desc 'POST agent events' do
            detail 'Updates agent events'
          end
          params do
            optional :events, type: Hash, desc: 'Array of events' do
              optional :k8s_api_proxy_requests_unique_users_via_ci_access, type: Array, desc: 'An array of events that have interacted with the CI tunnel via `ci_access`' do
                optional :user_id, type: Integer, desc: 'User ID'
                optional :project_id, type: Integer, desc: 'Project ID'
              end
              optional :k8s_api_proxy_requests_unique_users_via_user_access, type: Array, desc: 'An array of events that have interacted with the CI tunnel via `ci_access`' do
                optional :user_id, type: Integer, desc: 'User ID'
                optional :project_id, type: Integer, desc: 'Project ID'
              end
              optional :k8s_api_proxy_requests_unique_users_via_pat_access, type: Array, desc: 'An array of events that have interacted with the CI tunnel via `ci_access`' do
                optional :user_id, type: Integer, desc: 'User ID'
                optional :project_id, type: Integer, desc: 'Project ID'
              end
              optional :register_agent_at_kas, type: Array, desc: 'An array of events that indicate an agent has been registered' do
                optional :project_id, type: Integer, desc: 'Project ID'
                optional :agent_version, type: String, desc: 'Agent version'
                optional :architecture, type: String, desc: 'CPU architecture of the agent'
              end
            end
          end
          post '/', feature_category: :deployment_management do
            track_events

            no_content!
          end
        end
      end
    end
  end
end

API::Internal::Kubernetes.prepend_mod_with('API::Internal::Kubernetes')
