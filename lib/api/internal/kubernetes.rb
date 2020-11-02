# frozen_string_literal: true

module API
  # Kubernetes Internal API
  module Internal
    class Kubernetes < Grape::API::Instance
      helpers do
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
          not_found! unless Feature.enabled?(:kubernetes_agent_internal_api)
        end

        def check_agent_token
          forbidden! unless agent_token
        end
      end

      namespace 'internal' do
        namespace 'kubernetes' do
          before do
            check_feature_enabled
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

            # TODO sort out authorization for real
            # https://gitlab.com/gitlab-org/gitlab/-/issues/220912
            unless Ability.allowed?(nil, :download_code, project)
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
      end
    end
  end
end
