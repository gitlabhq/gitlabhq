module API
  module V3
    class GithubRepos < Grape::API
      before { authenticate! }

      helpers do
        params :project_full_path do
          requires :namespace, type: String
          requires :project, type: String
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
        get ':namespace/repos' do
          projects = current_user.authorized_projects.select { |project| project.feature_available?(:jira_dev_panel_integration) }
          projects = ::Kaminari.paginate_array(projects)
          present paginate(projects), with: ::API::Entities::Github::Repository
        end
      end

      resource :repos do
        get '/-/jira/pulls' do
          present []
        end

        params do
          use :project_full_path
        end
        get ':namespace/:project/branches' do
          namespace = params[:namespace]
          project = params[:project]
          user_project = find_project_with_access("#{namespace}/#{project}")

          branches = ::Kaminari.paginate_array(user_project.repository.branches.sort_by(&:name))

          present paginate(branches),
                  with: ::API::Entities::Github::Branch,
                  project: user_project
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

          present commit, with: ::API::Entities::Github::RepoCommit
        end
      end
    end
  end
end
