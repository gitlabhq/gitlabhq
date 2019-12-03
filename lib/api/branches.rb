# frozen_string_literal: true

require 'mime/types'

module API
  class Branches < Grape::API
    include PaginationParams

    BRANCH_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(branch: API::NO_SLASH_URL_PART_REGEX)

    before do
      require_repository_enabled!
      authorize! :download_code, user_project
    end

    helpers do
      params :filter_params do
        optional :search, type: String, desc: 'Return list of branches matching the search criteria'
        optional :sort, type: String, desc: 'Return list of branches sorted by the given field'
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a project repository branches' do
        success Entities::Branch
      end
      params do
        use :pagination
        use :filter_params
      end
      get ':id/repository/branches' do
        user_project.preload_protected_branches

        repository = user_project.repository

        branches = BranchesFinder.new(repository, declared_params(include_missing: false)).execute
        branches = paginate(::Kaminari.paginate_array(branches))
        merged_branch_names = repository.merged_branch_names(branches.map(&:name))

        present(
          branches,
          with: Entities::Branch,
          current_user: current_user,
          project: user_project,
          merged_branch_names: merged_branch_names
        )
      end

      resource ':id/repository/branches/:branch', requirements: BRANCH_ENDPOINT_REQUIREMENTS do
        desc 'Get a single branch' do
          success Entities::Branch
        end
        params do
          requires :branch, type: String, desc: 'The name of the branch'
        end
        head do
          user_project.repository.branch_exists?(params[:branch]) ? status(204) : status(404)
        end
        get do
          branch = find_branch!(params[:branch])

          present branch, with: Entities::Branch, current_user: current_user, project: user_project
        end
      end

      # Note: This API will be deprecated in favor of the protected branches API.
      # Note: The internal data model moved from `developers_can_{merge,push}` to `allowed_to_{merge,push}`
      # in `gitlab-org/gitlab-ce!5081`. The API interface has not been changed (to maintain compatibility),
      # but it works with the changed data model to infer `developers_can_merge` and `developers_can_push`.
      desc 'Protect a single branch' do
        success Entities::Branch
      end
      params do
        requires :branch, type: String, desc: 'The name of the branch', allow_blank: false
        optional :developers_can_push, type: Boolean, desc: 'Flag if developers can push to that branch'
        optional :developers_can_merge, type: Boolean, desc: 'Flag if developers can merge to that branch'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      put ':id/repository/branches/:branch/protect', requirements: BRANCH_ENDPOINT_REQUIREMENTS do
        authorize_admin_project

        branch = find_branch!(params[:branch])

        protected_branch = user_project.protected_branches.find_by(name: branch.name)

        protected_branch_params = {
          name: branch.name,
          developers_can_push: params[:developers_can_push],
          developers_can_merge: params[:developers_can_merge]
        }

        service_args = [user_project, current_user, protected_branch_params]

        protected_branch = if protected_branch
                             ::ProtectedBranches::LegacyApiUpdateService.new(*service_args).execute(protected_branch)
                           else
                             ::ProtectedBranches::LegacyApiCreateService.new(*service_args).execute
                           end

        if protected_branch.valid?
          present branch, with: Entities::Branch, current_user: current_user, project: user_project
        else
          render_api_error!(protected_branch.errors.full_messages, 422)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Note: This API will be deprecated in favor of the protected branches API.
      desc 'Unprotect a single branch' do
        success Entities::Branch
      end
      params do
        requires :branch, type: String, desc: 'The name of the branch', allow_blank: false
      end
      # rubocop: disable CodeReuse/ActiveRecord
      put ':id/repository/branches/:branch/unprotect', requirements: BRANCH_ENDPOINT_REQUIREMENTS do
        authorize_admin_project

        branch = find_branch!(params[:branch])
        protected_branch = user_project.protected_branches.find_by(name: branch.name)
        protected_branch&.destroy

        present branch, with: Entities::Branch, current_user: current_user, project: user_project
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Create branch' do
        success Entities::Branch
      end
      params do
        requires :branch, type: String, desc: 'The name of the branch', allow_blank: false
        requires :ref, type: String, desc: 'Create branch from commit sha or existing branch', allow_blank: false
      end
      post ':id/repository/branches' do
        authorize_push_project

        result = ::Branches::CreateService.new(user_project, current_user)
                 .execute(params[:branch], params[:ref])

        if result[:status] == :success
          present result[:branch],
                  with: Entities::Branch,
                  current_user: current_user,
                  project: user_project
        else
          render_api_error!(result[:message], 400)
        end
      end

      desc 'Delete a branch'
      params do
        requires :branch, type: String, desc: 'The name of the branch', allow_blank: false
      end
      delete ':id/repository/branches/:branch', requirements: BRANCH_ENDPOINT_REQUIREMENTS do
        authorize_push_project

        branch = find_branch!(params[:branch])

        commit = user_project.repository.commit(branch.dereferenced_target)

        destroy_conditionally!(commit, last_updated: commit.authored_date) do
          result = ::Branches::DeleteService.new(user_project, current_user)
                    .execute(params[:branch])

          if result.error?
            render_api_error!(result.message, result.http_status)
          end
        end
      end

      desc 'Delete all merged branches'
      delete ':id/repository/merged_branches' do
        ::Branches::DeleteMergedService.new(user_project, current_user).async_execute

        accepted!
      end
    end
  end
end
