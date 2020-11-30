# frozen_string_literal: true

module API
  # Kubernetes Internal API
  module Internal
    class Kubernetes < ::API::Base
      feature_category :kubernetes_management

      before do
        check_feature_enabled
        authenticate_gitlab_kas_request!
      end

      helpers do
        def authenticate_gitlab_kas_request!
          unauthorized! unless Gitlab::Kas.verify_api_request(headers)
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
          not_found! unless Feature.enabled?(:kubernetes_agent_internal_api, default_enabled: true, type: :ops)
        end

        def check_agent_token
          forbidden! unless agent_token
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
          get '/agent_info' do
            project = agent.project

            status 200
            {
              project_id: project.id,
              agent_id: agent.id,
              agent_name: agent.name,
              gitaly_info: gitaly_info(project),
              gitaly_repository: gitaly_repository(project)
            }
          end

          desc 'Gets project info' do
            detail 'Retrieves project info (if authorized)'
          end
          route_setting :authentication, cluster_agent_token_allowed: true
          get '/project_info' do
            project = find_project(params[:id])

            unless Guest.can?(:download_code, project) || agent.has_access_to?(project)
              not_found!
            end

            status 200
            {
              project_id: project.id,
              gitaly_info: gitaly_info(project),
              gitaly_repository: gitaly_repository(project)
            }
          end
        end

        namespace 'kubernetes/usage_metrics' do
          desc 'POST usage metrics' do
            detail 'Updates usage metrics for agent'
          end
          params do
            requires :gitops_sync_count, type: Integer, desc: 'The count to increment the gitops_sync metric by'
          end
          post '/' do
            gitops_sync_count = params[:gitops_sync_count]

            if gitops_sync_count < 0
              bad_request!('gitops_sync_count must be greater than or equal to zero')
            else
              Gitlab::UsageDataCounters::KubernetesAgentCounter.increment_gitops_sync(gitops_sync_count)

              no_content!
            end
          end
        end
      end
    end
  end
end
