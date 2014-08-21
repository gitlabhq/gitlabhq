require 'mime/types'

module API
  # Projects API
  class Branches < Grape::API
    before { authenticate! }
    before { authorize! :download_code, user_project }

    resource :projects do
      # Get a project repository branches
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   GET /projects/:id/repository/branches
      get ":id/repository/branches" do
        present user_project.repo.heads.sort_by(&:name), with: Entities::RepoObject, project: user_project
      end

      # Get a single branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch (required) - The name of the branch
      # Example Request:
      #   GET /projects/:id/repository/branches/:branch
      get ':id/repository/branches/:branch', requirements: { branch: /.*/ } do
        @branch = user_project.repo.heads.find { |item| item.name == params[:branch] }
        not_found!("Branch does not exist") if @branch.nil?
        present @branch, with: Entities::RepoObject, project: user_project
      end

      # Protect a single branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch (required) - The name of the branch
      # Example Request:
      #   PUT /projects/:id/repository/branches/:branch/protect
      put ':id/repository/branches/:branch/protect',
          requirements: { branch: /.*/ } do

        authorize_admin_project

        @branch = user_project.repository.find_branch(params[:branch])
        not_found! unless @branch
        protected_branch = user_project.protected_branches.find_by(name: @branch.name)
        user_project.protected_branches.create(name: @branch.name) unless protected_branch

        present @branch, with: Entities::RepoObject, project: user_project
      end

      # Unprotect a single branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch (required) - The name of the branch
      # Example Request:
      #   PUT /projects/:id/repository/branches/:branch/unprotect
      put ':id/repository/branches/:branch/unprotect',
          requirements: { branch: /.*/ } do

        authorize_admin_project

        @branch = user_project.repository.find_branch(params[:branch])
        not_found! unless @branch
        protected_branch = user_project.protected_branches.find_by(name: @branch.name)
        protected_branch.destroy if protected_branch

        present @branch, with: Entities::RepoObject, project: user_project
      end

      # Create branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch_name (required) - The name of the branch
      #   ref (required) - Create branch from commit sha or existing branch
      # Example Request:
      #   POST /projects/:id/repository/branches
      post ":id/repository/branches" do
        authorize_push_project

        interactor = Projects::Repositories::CreateBranch
        result = interactor.perform(proejct: user_project,
                                    branch_name: params[:branch_name],
                                    ref: params[:ref],
                                    user: current_user)
        @branch = result[:branch]

        present @branch, with: Entities::RepoObject, project: user_project
      end

      # Delete branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch (required) - The name of the branch
      # Example Request:
      #   DELETE /projects/:id/repository/branches/:branch
      delete ":id/repository/branches/:branch" do
        authorize_push_project

        interactor = Projects::Repositories::DeleteBranch
        result = interactor.perform(proejct: user_project,
                                    branch_name: params[:branch],
                                    user: current_user)

        if result.success?
          true
        else
          render_api_error!(result[:message], 405)
        end
      end
    end
  end
end
