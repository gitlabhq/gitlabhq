module API
  module V3
    class GithubRepos < Grape::API
      before { authenticate! }

      helpers do
        params :project_full_path do
          requires :namespace, type: String
          requires :project, type: String
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
          present paginate(current_user.authorized_projects),
                  with: ::API::Entities::Github::Repository
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
          user_project = find_project!("#{namespace}/#{project}")

          branches = ::API::Entities::Github::Branch
                       .represent(user_project.repository.branches.sort_by(&:name), project: user_project)
                       .as_json

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
          user_project = find_project!("#{namespace}/#{project}")

          commit = user_project.commit(params[:sha])

          not_found! 'Commit' unless commit

          json_commit = ::API::Entities::Github::RepoCommit.represent(commit).as_json
          Rails.logger.info("JSON COMMIT: #{json_commit}")

          present commit, with: ::API::Entities::Github::RepoCommit
        end
      end
    end
  end
end
