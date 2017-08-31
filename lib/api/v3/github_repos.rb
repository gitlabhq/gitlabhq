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
        get ':username/repos' do
          projects = ProjectsFinder.new(current_user: current_user, params: project_finder_params).execute

          present paginate(projects), with: ::API::Entities::Github::Repository
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

          branches = ::Kaminari.paginate_array(user_project.repository.branches.sort_by(&:name))

          present paginate(branches),
                  with: ::API::Entities::Github::Branch,
                  project: user_project
        end

        get ':namespace/:repo/commits/:sha' do
          hash =
            {
              "sha" => "6367e27cc0928789a860676f560ceda6b41b6215",
              "commit" => {
                "author" => {
                  "name" => "oswaksd",
                  "email" => "oswluizf@gmail.com",
                  "date" => "2011-04-14T16:00:49Z"
                },
                "committer" => {
                  "name" => "oswaksd",
                  "email" => "oswluizf@gmail.com",
                  "date" => "2011-04-14T16:00:49Z"
                },
                "message" => "Fix all the bugs GL-1 [1]",
              },
              "author" => {
                "login" => "oswaldo",
                "gravatar_id" => "",
              },
              "committer" => {
                "login" => "oswaldo",
                "gravatar_id" => "",
              },
              "parents" => [
                {
                  "sha" => "357fb168fc667ef07a3303e4bb528fbcb2147430"
                }
              ],
              "files" => [
                {
                  "filename" => "file1.txt",
                  "additions" => 10,
                  "deletions" => 2,
                  "changes" => 12,
                  "status" => "modified",
                  "patch" => "@@ -29,7 +29,7 @@\n....."
                }
              ]
            }

          present hash
        end
      end
    end
  end
end
