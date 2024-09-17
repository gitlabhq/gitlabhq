# frozen_string_literal: true

module API
  class ProtectedBranches < ::API::Base
    include PaginationParams

    BRANCH_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(name: API::NO_SLASH_URL_PART_REGEX)

    feature_category :source_code_management

    helpers Helpers::ProtectedBranchesHelpers

    params do
      requires :id,
        types: [String, Integer],
        desc: 'The ID or URL-encoded path of the project',
        documentation: { example: 'gitlab-org/gitlab' }
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc "Get a project's protected branches" do
        success code: 200, model: Entities::ProtectedBranch
        is_array true
        failure [
          { code: 404, message: '404 Project Not Found' },
          { code: 401, message: '401 Unauthorized' }
        ]
      end
      params do
        use :pagination
        optional :search, type: String, desc: 'Search for a protected branch by name', documentation: { example: 'mai' }
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get ':id/protected_branches' do
        authorize_read_code!

        protected_branches =
          ProtectedBranchesFinder
            .new(user_project, params)
            .execute
            .preload(:push_access_levels, :merge_access_levels)

        present paginate(protected_branches), with: Entities::ProtectedBranch, project: user_project
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Get a single protected branch' do
        success code: 200, model: Entities::ProtectedBranch
        failure [
          { code: 404, message: '404 Project Not Found' },
          { code: 401, message: '401 Unauthorized' }
        ]
      end
      params do
        requires :name, type: String, desc: 'The name of the branch or wildcard', documentation: { example: 'main' }
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get ':id/protected_branches/:name', requirements: BRANCH_ENDPOINT_REQUIREMENTS do
        authorize_read_code!

        protected_branch = user_project.protected_branches.find_by!(name: params[:name])

        present protected_branch, with: Entities::ProtectedBranch, project: user_project
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Protect a single branch' do
        success code: 201, model: Entities::ProtectedBranch
        failure [
          { code: 422, message: 'name is missing' },
          { code: 409, message: "Protected branch 'main' already exists" },
          { code: 404, message: '404 Project Not Found' },
          { code: 401, message: '401 Unauthorized' }
        ]
      end
      params do
        requires :name, type: String, desc: 'The name of the protected branch', documentation: { example: 'main' }
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
        authorize_create_protected_branch!

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

      desc 'Update a protected branch' do
        success code: 200, model: Entities::ProtectedBranch
        failure [
          { code: 422, message: 'Push access levels access level has already been taken' },
          { code: 404, message: '404 Project Not Found' },
          { code: 401, message: '401 Unauthorized' },
          { code: 400, message: '400 Bad request' }
        ]
      end
      params do
        requires :name, type: String, desc: 'The name of the branch', documentation: { example: 'main' }
        optional :allow_force_push, type: Boolean,
          desc: 'Allow force push for all users with push access.',
          allow_blank: false

        use :optional_params_ee
      end
      # rubocop: disable CodeReuse/ActiveRecord
      patch ':id/protected_branches/:name', requirements: BRANCH_ENDPOINT_REQUIREMENTS do
        protected_branch = user_project.protected_branches.find_by!(name: params[:name])

        authorize_update_protected_branch!(protected_branch)

        declared_params = declared_params(include_missing: false)
        api_service = ::ProtectedBranches::ApiService.new(user_project, current_user, declared_params)
        protected_branch = api_service.update(protected_branch)

        if protected_branch.valid?
          present protected_branch, with: Entities::ProtectedBranch, project: user_project
        else
          render_api_error!(protected_branch.errors.full_messages, 422)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Unprotect a single branch'
      params do
        requires :name, type: String, desc: 'The name of the protected branch', documentation: { example: 'main' }
      end
      desc 'Unprotect a single branch' do
        success code: 204
        failure [
          { code: 404, message: '404 Project Not Found' },
          { code: 401, message: '401 Unauthorized' }
        ]
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ':id/protected_branches/:name', requirements: BRANCH_ENDPOINT_REQUIREMENTS, urgency: :low do
        protected_branch = user_project.protected_branches.find_by!(name: params[:name])

        authorize_destroy_protected_branch!(protected_branch)

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
