module Ci
  module API
    class Commits < Grape::API
      resource :commits do
        # Get list of commits per project
        #
        # Parameters:
        #   project_id (required) - The ID of a project
        #   project_token (requires) - Project token
        #   page (optional)
        #   per_page (optional) - items per request (default is 20)
        #
        get do
          required_attributes! [:project_id, :project_token]
          project = Ci::Project.find(params[:project_id])
          authenticate_project_token!(project)

          commits = project.commits.page(params[:page]).per(params[:per_page] || 20)
          present commits, with: Entities::CommitWithBuilds
        end

        # Create a commit
        #
        # Parameters:
        #   project_id (required) - The ID of a project
        #   project_token (requires) - Project token
        #   data (required) - GitLab push data
        #
        #   Sample GitLab push data:
        #   {
        #     "before": "95790bf891e76fee5e1747ab589903a6a1f80f22",
        #     "after": "da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
        #     "ref": "refs/heads/master",
        #     "commits": [
        #       {
        #         "id": "b6568db1bc1dcd7f8b4d5a946b0b91f9dacd7327",
        #         "message": "Update Catalan translation to e38cb41.",
        #         "timestamp": "2011-12-12T14:27:31+02:00",
        #         "url": "http://localhost/diaspora/commits/b6568db1bc1dcd7f8b4d5a946b0b91f9dacd7327",
        #         "author": {
        #           "name": "Jordi Mallach",
        #           "email": "jordi@softcatala.org",
        #         }
        #       }, .... more commits
        #     ]
        #   }
        #
        # Example Request:
        #   POST /commits
        post do
          required_attributes! [:project_id, :data, :project_token]
          project = Ci::Project.find(params[:project_id])
          authenticate_project_token!(project)
          commit = Ci::CreateCommitService.new.execute(project, current_user, params[:data])

          if commit.persisted?
            present commit, with: Entities::CommitWithBuilds
          else
            errors = commit.errors.full_messages.join(", ")
            render_api_error!(errors, 400)
          end
        end
      end
    end
  end
end
