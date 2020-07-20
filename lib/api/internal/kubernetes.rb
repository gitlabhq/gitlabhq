# frozen_string_literal: true

module API
  # Kubernetes Internal API
  module Internal
    class Kubernetes < Grape::API::Instance
      helpers do
        def repo_type
          Gitlab::GlRepository::PROJECT
        end

        def gl_repository(project)
          repo_type.identifier_for_container(project)
        end

        def gl_repository_path(project)
          repo_type.repository_for(project).full_path
        end

        def check_feature_enabled
          not_found! unless Feature.enabled?(:kubernetes_agent_internal_api)
        end
      end

      namespace 'internal' do
        namespace 'kubernetes' do
          desc 'Gets agent info' do
            detail 'Retrieves agent info for the given token'
          end
          route_setting :authentication, cluster_agent_token_allowed: true
          get '/agent_info' do
            check_feature_enabled

            agent_token = cluster_agent_token_from_authorization_token

            if agent_token
              agent = agent_token.agent
              project = agent.project
              @gl_project_string = "project-#{project.id}"

              status 200
              {
                project_id: project.id,
                agent_id: agent.id,
                agent_name: agent.name,
                storage_name: project.repository_storage,
                relative_path: project.disk_path + '.git',
                gl_repository: gl_repository(project),
                gl_project_path: gl_repository_path(project)
              }
            else
              status 403
            end
          end

          desc 'Gets project info' do
            detail 'Retrieves project info (if authorized)'
          end
          route_setting :authentication, cluster_agent_token_allowed: true
          get '/project_info' do
            check_feature_enabled

            agent_token = cluster_agent_token_from_authorization_token

            if agent_token
              project = find_project(params[:id])

              # TODO sort out authorization for real
              # https://gitlab.com/gitlab-org/gitlab/-/issues/220912
              if !project || !project.public?
                not_found!
              end

              @gl_project_string = "project-#{project.id}"

              status 200
              {
                project_id: project.id,
                storage_name: project.repository_storage,
                relative_path: project.disk_path + '.git',
                gl_repository: gl_repository(project),
                gl_project_path: gl_repository_path(project)
              }
            else
              status 403
            end
          end
        end
      end
    end
  end
end
