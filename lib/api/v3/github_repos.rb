module API
  module V3
    class GithubRepos < Grape::API
      before { authenticate! }

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
          present paginate(current_user.authorized_projects), with: ::API::Entities::Github::Repository
        end
      end

      params do
        requires :namespace, type: String
        requires :project, type: String
      end
      resource :repos do
        get ':namespace/:project/branches' do
          namespace = params[:namespace]
          project = params[:project]
          user_project = find_project!("#{namespace}/#{project}")

          branches = ::API::Entities::Github::Branch
                       .represent(user_project.repository.branches.sort_by(&:name), project: user_project)
                       .as_json

          Rails.logger.info("BRANCHES: #{branches}")

          branches = ::Kaminari.paginate_array(user_project.repository.branches.sort_by(&:name))

          present paginate(branches),
                  with: ::API::Entities::Github::Branch,
                  project: user_project
        end

        params do
          requires :namespace, type: String
          requires :project, type: String
        end
        get ':namespace/:project/commits/:sha' do
          Rails.logger.info("FETCHING COMMITS FOR #{params[:namespace]}/#{params[:project]} [hardcoded]")
          namespace = params[:namespace]
          project = params[:project]
          user_project = find_project!("#{namespace}/#{project}")

          # sent :sha HAS to match with the returned sha on commit in order to succeed

          commit = user_project.commit(params[:sha])

          not_found! 'Commit' unless commit

          json_commit = ::API::Entities::Github::RepoCommit.represent(commit).as_json
          Rails.logger.info("JSON COMMIT: #{json_commit}")

          present commit, with: ::API::Entities::Github::RepoCommit

          # hash =
          #   {
          #     "sha" => "357fb168fc667ef07a3303e4bb528fbcb2147430",
          #     "commit" => {
          #       "author" => {
          #         "name" => "oswaksd",
          #         "email" => "oswluizf@gmail.com",
          #         "date" => "2011-04-14T16:00:49Z"
          #       },
          #       "committer" => {
          #         "name" => "oswaksd",
          #         "email" => "oswluizf@gmail.com",
          #         "date" => "2011-04-14T16:00:49Z"
          #       },
          #       "message" => "hardcoded GL-2",
          #     },
          #     "author" => {
          #       "login" => "oswaldo",
          #       "gravatar_id" => "",
          #     },
          #     "committer" => {
          #       "login" => "oswaldo",
          #       "gravatar_id" => "",
          #     },
          #     "parents" => [
          #       {
          #         "sha" => "357fb168fc667ef07a3303e4bb528fbcb2147430"
          #       }
          #     ],
          #     "files" => [
          #       {
          #         "filename" => "file1.txt",
          #         "additions" => 10,
          #         "deletions" => 2,
          #         "changes" => 12,
          #         "status" => "modified",
          #         "patch" => "@@ -29,7 +29,7 @@\n....."
          #       }
          #     ]
          #   }

          #present hash
        end
      end
    end
  end
end
