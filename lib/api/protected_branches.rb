# frozen_string_literal: true

module API
  class ProtectedBranches < ::API::Base
    include PaginationParams

    BRANCH_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(name: API::NO_SLASH_URL_PART_REGEX)

    before { authorize_admin_project }

    feature_category :source_code_management

    helpers Helpers::ProtectedBranchesHelpers

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc "Get a project's protected branches" do
        success Entities::ProtectedBranch
      end
      params do
        use :pagination
        optional :search, type: String, desc: 'Search for a protected branch by name'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get ':id/protected_branches' do
        protected_branches =
          ProtectedBranchesFinder
            .new(user_project, params)
            .execute
            .preload(:push_access_levels, :merge_access_levels)

        present paginate(protected_branches), with: Entities::ProtectedBranch, project: user_project
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Get a single protected branch' do
        success Entities::ProtectedBranch
      end
      params do
        requires :name, type: String, desc: 'The name of the branch or wildcard'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get ':id/protected_branches/:name', requirements: BRANCH_ENDPOINT_REQUIREMENTS do
        protected_branch = user_project.protected_branches.find_by!(name: params[:name])

        present protected_branch, with: Entities::ProtectedBranch, project: user_project
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Protect a single branch' do
        success Entities::ProtectedBranch
      end
      params do
        requires :name, type: String, desc: 'The name of the protected branch'
        optional :push_access_level, type: Integer,
                                     values: ProtectedBranch::PushAccessLevel.allowed_access_levels,
                                     desc: 'Access levels allowed to push (defaults: `40`, maintainer access level)'
        optional :merge_access_level, type: Integer,
                                      values: ProtectedBranch::MergeAccessLevel.allowed_access_levels,
                                      desc: 'Access levels allowed to merge (defaults: `40`, maintainer access level)'
        optional :allow_force_push, type: Boolean,
                                      default: false,
                                      desc: 'Allow force push for all users with push access.'

        use :optional_params_ee
      end
      # rubocop: disable CodeReuse/ActiveRecord
      post ':id/protected_branches' do
        protected_branch = user_project.protected_branches.find_by(name: params[:name])

        if protected_branch
          conflict!("Protected branch '#{params[:name]}' already exists")
        end

        declared_params = declared_params(include_missing: false)
        api_service = ::ProtectedBranches::ApiService.new(user_project, current_user, declared_params)
        protected_branch = api_service.create

        if protected_branch.persisted?
          present protected_branch, with: Entities::ProtectedBranch, project: user_project
        else
          render_api_error!(protected_branch.errors.full_messages, 422)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Unprotect a single branch'
      params do
        requires :name, type: String, desc: 'The name of the protected branch'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ':id/protected_branches/:name', requirements: BRANCH_ENDPOINT_REQUIREMENTS do
        protected_branch = user_project.protected_branches.find_by!(name: params[:name])

        destroy_conditionally!(protected_branch) do
          destroy_service = ::ProtectedBranches::DestroyService.new(user_project, current_user)
          destroy_service.execute(protected_branch)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end

API::ProtectedBranches.prepend_mod_with('API::ProtectedBranches')
