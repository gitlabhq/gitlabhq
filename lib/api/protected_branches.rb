module API
  class ProtectedBranches < Grape::API
    include PaginationParams

    BRANCH_ENDPOINT_REQUIREMENTS = API::PROJECT_ENDPOINT_REQUIREMENTS.merge(branch: API::NO_SLASH_URL_PART_REGEX)

    before { authorize_admin_project }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc "Get a project's protected branches" do
        success Entities::ProtectedBranch
      end
      params do
        use :pagination
      end
      get ':id/protected_branches' do
        protected_branches = user_project.protected_branches.preload(:push_access_levels, :merge_access_levels)

        present paginate(protected_branches), with: Entities::ProtectedBranch, project: user_project
      end

      desc 'Get a single protected branch' do
        success Entities::ProtectedBranch
      end
      params do
        requires :name, type: String, desc: 'The name of the branch or wildcard'
      end
      get ':id/protected_branches/:name', requirements: BRANCH_ENDPOINT_REQUIREMENTS do
        protected_branch = user_project.protected_branches.find_by!(name: params[:name])

        present protected_branch, with: Entities::ProtectedBranch, project: user_project
      end

      desc 'Protect a single branch or wildcard' do
        success Entities::ProtectedBranch
      end
      params do
        requires :name, type: String, desc: 'The name of the protected branch'
        optional :push_access_level, type: Integer, default: Gitlab::Access::MASTER,
                                     values: ProtectedRefAccess::ALLOWED_ACCESS_LEVELS,
                                     desc: 'Access levels allowed to push (defaults: `40`, master access level)'
        optional :merge_access_level, type: Integer, default: Gitlab::Access::MASTER,
                                      values: ProtectedRefAccess::ALLOWED_ACCESS_LEVELS,
                                      desc: 'Access levels allowed to merge (defaults: `40`, master access level)'
      end
      post ':id/protected_branches' do
        protected_branch = user_project.protected_branches.find_by(name: params[:name])
        if protected_branch
          conflict!("Protected branch '#{params[:name]}' already exists")
        end

        protected_branch_params = {
          name: params[:name],
          push_access_levels_attributes: [{ access_level: params[:push_access_level] }],
          merge_access_levels_attributes: [{ access_level: params[:merge_access_level] }]
        }

        service_args = [user_project, current_user, protected_branch_params]

        protected_branch = ::ProtectedBranches::CreateService.new(*service_args).execute

        if protected_branch.persisted?
          present protected_branch, with: Entities::ProtectedBranch, project: user_project
        else
          render_api_error!(protected_branch.errors.full_messages, 422)
        end
      end

      desc 'Unprotect a single branch'
      params do
        requires :name, type: String, desc: 'The name of the protected branch'
      end
      delete ':id/protected_branches/:name', requirements: BRANCH_ENDPOINT_REQUIREMENTS do
        protected_branch = user_project.protected_branches.find_by!(name: params[:name])

        destroy_conditionally!(protected_branch)
      end
    end
  end
end
