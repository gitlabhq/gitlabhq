# frozen_string_literal: true

module API
  # Kubernetes Internal API
  module Internal
    class Kubernetes < ::API::Base
      include Gitlab::Utils::StrongMemoize

      feature_category :kubernetes_management
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
          not_found! unless Feature.enabled?(:kubernetes_agent_internal_api, type: :ops)
        end

        def check_agent_token
          unauthorized! unless agent_token

          ::Clusters::AgentTokens::TrackUsageService.new(agent_token).execute
        end

        def agent_has_access_to_project?(project)
          Guest.can?(:download_code, project) || agent.has_access_to?(project)
        end

        def count_events
          strong_memoize(:count_events) do
            events = params.slice(:gitops_sync_count, :k8s_api_proxy_request_count)
            events.transform_keys! { |event| event.to_s.chomp('_count') }
            events = params[:counters]&.slice(:gitops_sync, :k8s_api_proxy_request) unless events.present?
            events
          end
        end

        def increment_unique_events
          events = params[:unique_counters]&.slice(:agent_users_using_ci_tunnel)

          events&.each do |event, entity_ids|
            increment_unique_values(event, entity_ids)
          end
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
          get '/agent_info', urgency: :low do
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
          get '/project_info', urgency: :low do
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

        namespace 'kubernetes/agent_configuration', urgency: :low do
          desc 'POST agent configuration' do
            detail 'Store configuration for an agent'
          end
          params do
            requires :agent_id, type: Integer, desc: 'ID of the configured Agent'
            requires :agent_config, type: JSON, desc: 'Configuration for the Agent'
          end
          post '/' do
            agent = ::Clusters::Agent.find(params[:agent_id])

            ::Clusters::Agents::RefreshAuthorizationService.new(agent, config: params[:agent_config]).execute

            no_content!
          end
        end

        namespace 'kubernetes/usage_metrics' do
          desc 'POST usage metrics' do
            detail 'Updates usage metrics for agent'
          end
          params do
            # Todo: Remove gitops_sync_count and k8s_api_proxy_request_count in the next milestone
            #       https://gitlab.com/gitlab-org/gitlab/-/issues/369489
            #       We're only keeping it for backwards compatibility until KAS is released
            #       using `counts:` instead
            optional :gitops_sync_count, type: Integer, desc: 'The count to increment the gitops_sync metric by'
            optional :k8s_api_proxy_request_count, type: Integer, desc: 'The count to increment the k8s_api_proxy_request_count metric by'
            optional :counters, type: Hash do
              optional :gitops_sync, type: Integer, desc: 'The count to increment the gitops_sync metric by'
              optional :k8s_api_proxy_request, type: Integer, desc: 'The count to increment the k8s_api_proxy_request_count metric by'
            end
            mutually_exclusive :counters, :gitops_sync_count
            mutually_exclusive :counters, :k8s_api_proxy_request_count

            optional :unique_counters, type: Hash do
              optional :agent_users_using_ci_tunnel, type: Set[Integer], desc: 'A set of user ids that have interacted a CI Tunnel to'
            end
          end
          post '/' do
            Gitlab::UsageDataCounters::KubernetesAgentCounter.increment_event_counts(count_events) if count_events

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
