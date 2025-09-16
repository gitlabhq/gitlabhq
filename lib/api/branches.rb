# frozen_string_literal: true

require 'mime/types'

module API
  class Branches < ::API::Base
    include PaginationParams

    BRANCH_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(branch: API::NO_SLASH_URL_PART_REGEX)

    after_validation { content_type "application/json" }

    feature_category :source_code_management

    before do
      require_repository_enabled!
      authorize_read_code!
    end

    rescue_from Gitlab::Git::Repository::NoRepository do
      not_found!
    end

    helpers do
      params :filter_params do
        optional :search, type: String, desc: 'Return list of branches matching the search criteria'
        optional :regex, type: String, desc: 'Return list of branches matching the regex'
        optional :sort, type: String, desc: 'Return list of branches sorted by the given field', values: %w[name_asc updated_asc updated_desc]
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a project repository branches' do
        success Entities::Branch
        success code: 200, model: Entities::Branch
        failure [{ code: 404, message: '404 Project Not Found' }]
        tags %w[branches]
        is_array true
      end
      params do
        use :pagination
        use :filter_params

        optional :page_token, type: String, desc: 'Name of branch to start the pagination from'
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, job_token_policies: :read_repositories,
        allow_public_access_for_enabled_project_features: :repository
      get ':id/repository/branches', urgency: :low do
        cache_action([user_project, :branches, current_user, declared_params], expires_in: 30.seconds) do
          repository = user_project.repository

          branches_finder = BranchesFinder.new(repository, declared_params(include_missing: false))
          branches = Gitlab::Pagination::GitalyKeysetPager.new(self, user_project).paginate(branches_finder)

          merged_branch_names = repository.merged_branch_names(branches.map(&:name))

          user_project.preload_protected_branches if branches.present?
          present_cached(
            branches,
            with: Entities::Branch,
            current_user: current_user,
            project: user_project,
            merged_branch_names: merged_branch_names,
            expires_in: 60.minutes,
            cache_context: ->(branch) {
              [
                user_project.cache_key,
                current_user&.cache_key,
                merged_branch_names.include?(branch.name),
                user_project.default_branch
              ]
            }
          )
        end
      rescue RegexpError
        render_api_error!('Regex is invalid', 400)
      end

      resource ':id/repository/branches/:branch', requirements: BRANCH_ENDPOINT_REQUIREMENTS do
        params do
          requires :branch, type: String, desc: 'The name of the branch'
        end
        desc 'Check if a branch exists' do
          success [{ code: 204, message: 'No Content' }]
          failure [{ code: 404, message: 'Not Found' }]
          tags %w[branches]
        end
        head do
          user_project.repository.branch_exists?(params[:branch]) ? no_content! : not_found!
        end
        desc 'Get a single repository branch' do
          success Entities::Branch
          success code: 200, model: Entities::Branch
          failure [{ code: 404, message: 'Branch Not Found' }, { code: 404, message: 'Project Not Found' }]
          tags %w[branches]
        end
        get '/', urgency: :low do
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
        success code: 200, model: Entities::Branch
        failure [{ code: 404, message: '404 Branch Not Found' }]
        tags %w[branches]
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
        success code: 200, model: Entities::Branch
        failure [{ code: 404, message: '404 Project Not Found' }, { code: 404, message: '404 Branch Not Found' }]
        tags %w[branches]
      end
      params do
        requires :branch, type: String, desc: 'The name of the branch', allow_blank: false
      end
      # rubocop: disable CodeReuse/ActiveRecord
      put ':id/repository/branches/:branch/unprotect', requirements: BRANCH_ENDPOINT_REQUIREMENTS do
        authorize_admin_project

        branch = find_branch!(params[:branch])
        protected_branch = user_project.protected_branches.find_by(name: branch.name)

        ::ProtectedBranches::DestroyService.new(user_project, current_user).execute(protected_branch) if protected_branch

        present branch, with: Entities::Branch, current_user: current_user, project: user_project
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Create branch' do
        success Entities::Branch
        success code: 201, model: Entities::Branch
        failure [{ code: 400, message: 'Failed to create branch' }, { code: 400, message: 'Branch already exists' }]
        tags %w[branches]
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

      desc 'Delete a branch' do
        success code: 204
        failure [{ code: 404, message: 'Branch Not Found' }]
        tags %w[branches]
      end
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

      desc 'Delete all merged branches' do
        success code: 202, message: '202 Accepted'
        failure [{ code: 404, message: '404 Project Not Found' }]
        tags %w[branches]
      end
      delete ':id/repository/merged_branches' do
        authorize_push_project

        ::Branches::DeleteMergedService.new(user_project, current_user).async_execute

        accepted!
      end
    end
  end
end
