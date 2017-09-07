# These endpoints partially mimic Github API behavior in order to successfully
# integrate with Jira Development Panel.
# Endpoints returning an empty list were temporarily added to avoid 404's
# during Jira's DVCS integration.
#
module API
  module V3
    class Github < Grape::API
      include PaginationParams

      before do
        authorize_jira_user_agent!(request)
        authenticate!
      end

      helpers do
        params :project_full_path do
          requires :namespace, type: String
          requires :project, type: String
        end

        def authorize_jira_user_agent!(request)
          not_found! unless Gitlab::Jira::Middleware.jira_dvcs_connector?(request.env)
        end

        def find_project_with_access(full_path)
          project = find_project!(full_path)
          not_found! unless project.feature_available?(:jira_dev_panel_integration)
          project
        end
      end

      resource :orgs do
        get ':namespace/repos' do
          present []
        end
      end

      resource :user do
        get :repos do
          present []
        end
      end

      resource :users do
        params do
          use :pagination
        end
        get ':namespace/repos' do
          projects = current_user.authorized_projects.select { |project| project.feature_available?(:jira_dev_panel_integration) }
          projects = ::Kaminari.paginate_array(projects)
          present paginate(projects), with: ::API::Github::Entities::Repository
        end
      end

      resource :repos do
        get '/-/jira/pulls' do
          present []
        end

        params do
          use :project_full_path
          use :pagination
        end
        get ':namespace/:project/branches' do
          namespace = params[:namespace]
          project = params[:project]
          user_project = find_project_with_access("#{namespace}/#{project}")

          branches = ::Kaminari.paginate_array(user_project.repository.branches.sort_by(&:name))

          present paginate(branches), with: ::API::Github::Entities::Branch, project: user_project
        end

        params do
          use :project_full_path
        end
        get ':namespace/:project/commits/:sha' do
          namespace = params[:namespace]
          project = params[:project]
          user_project = find_project_with_access("#{namespace}/#{project}")

          commit = user_project.commit(params[:sha])

          not_found! 'Commit' unless commit

          present commit, with: ::API::Github::Entities::RepoCommit
        end
      end
    end
  end
end
