require 'mime/types'

module API
  # Projects API
  class Branches < Grape::API
    before { authenticate! }
    before { authorize! :download_code, user_project }

    resource :projects do
      params do
        requires :id, type: String, desc: 'The ID of a project'
      end

      desc 'Get a project repository branches' do
        success Entities::RepoBranch
      end
      get ":id/repository/branches" do
        branches = user_project.repository.branches.sort_by(&:name)

        present branches, with: Entities::RepoBranch, project: user_project
      end

      desc 'Get a single branch' do
        success Entities::RepoBranch
      end
      params do
        requires :branch, type: String, regexp: /.+/, desc 'The name of the branch'
      end
      get ':id/repository/branches/:branch' do
        branch = user_project.repository.branches.find { |item| item.name == params[:branch] }
        not_found!("Branch") unless branch

        present branch, with: Entities::RepoBranch, project: user_project
      end

      # Note: The internal data model moved from `developers_can_{merge,push}` to `allowed_to_{merge,push}`
      # in `gitlab-org/gitlab-ce!5081`. The API interface has not been changed (to maintain compatibility),
      # but it works with the changed data model to infer `developers_can_merge` and `developers_can_push`.
      desc 'Protect a single branch' do
        success Entities::RepoBranch
      end
      params do
        requires :branch, type: String, regexp: /.+/, desc 'The name of the branch'
        optional :developers_can_push, type: String, desc 'Flag if developers can push to that branch'
        optional :developers_can_merge, type: String, desc 'Flag if developers can merge to that branch'
      end
      put ':id/repository/branches/:branch/protect' do
        authorize_admin_project

        branch = user_project.repository.find_branch(params[:branch])
        not_found!('Branch') unless branch
        protected_branch = user_project.protected_branches.find_by(name: branch.name)

        developers_can_merge = to_boolean(params[:developers_can_merge])
        developers_can_push = to_boolean(params[:developers_can_push])

        protected_branch_params = {
          name: branch.name
        }

        # If `developers_can_merge` is switched off, _all_ `DEVELOPER`
        # merge_access_levels need to be deleted.
        if developers_can_merge == false
          protected_branch.merge_access_levels.where(access_level: Gitlab::Access::DEVELOPER).destroy_all
        end

        # If `developers_can_push` is switched off, _all_ `DEVELOPER`
        # push_access_levels need to be deleted.
        if developers_can_push == false
          protected_branch.push_access_levels.where(access_level: Gitlab::Access::DEVELOPER).destroy_all
        end

        protected_branch_params.merge!(
          merge_access_levels_attributes: [{
            access_level: developers_can_merge ? Gitlab::Access::DEVELOPER : Gitlab::Access::MASTER
          }],
          push_access_levels_attributes: [{
            access_level: developers_can_push ? Gitlab::Access::DEVELOPER : Gitlab::Access::MASTER
          }]
        )

        if protected_branch
          service = ProtectedBranches::UpdateService.new(user_project, current_user, protected_branch_params)
          service.execute(protected_branch)
        else
          service = ProtectedBranches::CreateService.new(user_project, current_user, protected_branch_params)
          service.execute
        end

        present branch, with: Entities::RepoBranch, project: user_project
      end

      desc 'Unprotect a single branch' do
        success Entities::RepoBranch
      end
      params do
        requires :branch, type: String, regexp: /.+/, desc 'The name of the branch'
      end
      put ':id/repository/branches/:branch/unprotect' do
        authorize_admin_project

        branch = user_project.repository.find_branch(params[:branch])
        not_found!("Branch") unless branch
        protected_branch = user_project.protected_branches.find_by(name: branch.name)
        protected_branch.destroy if protected_branch

        present branch, with: Entities::RepoBranch, project: user_project
      end

      desc 'Create branch' do
        success Entities::RepoBranch
      end
      params do
        requires :branch_name, type: String, desc: 'The name of the branch'
        requires :ref, type: String, desc: 'Create branch from commit sha or existing branch'
      end
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

      desc 'Delete a branch'
      params do
        requires :branch, type: String, regexp: /.+/, desc 'The name of the branch'
      end
      delete ":id/repository/branches/:branch" do
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
