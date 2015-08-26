module Ci
  module API
    class Forks < Grape::API
      resource :forks do
        # Create a fork
        #
        # Parameters:
        #   project_id (required) - The ID of a project
        #   project_token (requires) - Project token
        #   private_token(required) - User private token
        #   data (required) - GitLab project data (name_with_namespace, web_url, default_branch, ssh_url_to_repo)
        #
        #
        # Example Request:
        #   POST /forks
        post do
          required_attributes! [:project_id, :data, :project_token, :private_token]
          project = Ci::Project.find_by!(gitlab_id: params[:project_id])
          authenticate_project_token!(project)

          user_session = Ci::UserSession.new
          user = user_session.authenticate(private_token: params[:private_token])

          fork = Ci::CreateProjectService.new.execute(
            user,
            params[:data],
            Ci::RoutesHelper.ci_project_url(":project_id"),
            project
          )

          if fork
            present fork, with: Entities::Project
          else
            not_found!
          end
        end
      end
    end
  end
end
