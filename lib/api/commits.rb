module Gitlab
  # Commits API
  class Commits < Grape::API
    before { authenticate! }

    resource :projects do
      # Get a list of project commits
      #
      # Parameters:
      #   id (required) - The ID or code name of a project
      #   ref_name (optional) - Name of branch or tag
      #   page (optional) - default is 0
      #   per_page (optional) - default is 20
      # Example Request:
      #   GET /projects/:id/commits
      get ":id/commits" do
        authorize! :download_code, user_project

        page = params[:page] || 0
        per_page = params[:per_page] || 20
        ref = params[:ref_name] || user_project.try(:default_branch) || 'master'

        commits = user_project.commits(ref, nil, per_page, page * per_page)

        present CommitDecorator.decorate(commits), with: Entities::Commit
      end
    end
  end
end
