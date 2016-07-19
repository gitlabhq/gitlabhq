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
        branches = user_project.repository.branches.sort_by(&:name)

        present branches, with: Entities::RepoBranch, project: user_project
      end

      # Get a single branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch (required) - The name of the branch
      # Example Request:
      #   GET /projects/:id/repository/branches/:branch
      get ':id/repository/branches/:branch', requirements: { branch: /.+/ } do
        @branch = user_project.repository.branches.find { |item| item.name == params[:branch] }
        not_found!("Branch") unless @branch

        present @branch, with: Entities::RepoBranch, project: user_project
      end

      # Protect a single branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch (required) - The name of the branch
      #   developers_can_push (optional) - Flag if developers can push to that branch
      #   developers_can_merge (optional) - Flag if developers can merge to that branch
      # Example Request:
      #   PUT /projects/:id/repository/branches/:branch/protect
      put ':id/repository/branches/:branch/protect',
          requirements: { branch: /.+/ } do
        authorize_admin_project

        @branch = user_project.repository.find_branch(params[:branch])
        not_found!('Branch') unless @branch
        protected_branch = user_project.protected_branches.find_by(name: @branch.name)
        developers_can_push = to_boolean(params[:developers_can_push])
        developers_can_merge = to_boolean(params[:developers_can_merge])

        if protected_branch
          protected_branch.developers_can_push = developers_can_push unless developers_can_push.nil?
          protected_branch.developers_can_merge = developers_can_merge unless developers_can_merge.nil?
          protected_branch.save
        else
          user_project.protected_branches.create(name: @branch.name,
                                                 developers_can_push: developers_can_push || false,
                                                 developers_can_merge: developers_can_merge || false)
        end

        present @branch, with: Entities::RepoBranch, project: user_project
      end

      # Unprotect a single branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch (required) - The name of the branch
      # Example Request:
      #   PUT /projects/:id/repository/branches/:branch/unprotect
      put ':id/repository/branches/:branch/unprotect',
          requirements: { branch: /.+/ } do
        authorize_admin_project

        @branch = user_project.repository.find_branch(params[:branch])
        not_found!("Branch") unless @branch
        protected_branch = user_project.protected_branches.find_by(name: @branch.name)
        protected_branch.destroy if protected_branch

        present @branch, with: Entities::RepoBranch, project: user_project
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
        result = CreateBranchService.new(user_project, current_user).
          execute(params[:branch_name], params[:ref])

        if result[:status] == :success
          present result[:branch],
                  with: Entities::RepoBranch,
                  project: user_project
        else
          render_api_error!(result[:message], 400)
        end
      end

      # Delete branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch (required) - The name of the branch
      # Example Request:
      #   DELETE /projects/:id/repository/branches/:branch
      delete ":id/repository/branches/:branch",
          requirements: { branch: /.+/ } do
        authorize_push_project
        result = DeleteBranchService.new(user_project, current_user).
          execute(params[:branch])

        if result[:status] == :success
          {
            branch_name: params[:branch]
          }
        else
          render_api_error!(result[:message], result[:return_code])
        end
      end
    end
  end
end
