# frozen_string_literal: true

module API
  class ProjectJobTokenScope < ::API::Base
    include PaginationParams

    before { authenticate! }

    feature_category :secrets_management
    urgency :low

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Fetch CI_JOB_TOKEN access settings.' do
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        success code: 200, model: Entities::ProjectJobTokenScope
        tags %w[projects_job_token_scope]
      end
      get ':id/job_token_scope' do
        authorize_admin_project

        present user_project, with: Entities::ProjectJobTokenScope
      end

      desc 'Patch CI_JOB_TOKEN access settings.' do
        failure [
          { code: 400, message: 'Bad Request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        success code: 204
        tags %w[projects_job_token_scope]
      end
      params do
        requires :enabled,
          type: Boolean,
          as: :ci_inbound_job_token_scope_enabled,
          allow_blank: false,
          desc: "Indicates CI/CD job tokens generated in other projects have restricted access to this project."
      end

      patch ':id/job_token_scope' do
        authorize_admin_project

        job_token_scope_params = declared_params(include_missing: false)
        result = ::Projects::UpdateService.new(user_project, current_user, job_token_scope_params).execute

        break bad_request!(result[:message]) if result[:status] == :error

        no_content!
      end

      desc 'Fetch project inbound allowlist for CI_JOB_TOKEN access settings.' do
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        success status: 200, model: Entities::BasicProjectDetails
        tags %w[projects_job_token_scope]
      end
      params do
        use :pagination
      end
      get ':id/job_token_scope/allowlist' do
        authorize_admin_project

        inbound_projects = ::Ci::JobToken::Scope.new(user_project).inbound_projects

        present paginate(inbound_projects), with: Entities::BasicProjectDetails
      end

      desc 'Delete project from allowlist.' do
        failure [
          { code: 400, message: 'Bad Request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        success code: 204
        tags %w[projects_job_token_scope]
      end

      params do
        requires :id, type: Integer, desc: 'ID of user project', documentation: { example: 1 }
        requires :target_project_id, type: Integer,
          desc: 'ID of the project to be removed from the allowlist', documentation: { example: 2 }
      end
      delete ':id/job_token_scope/allowlist/:target_project_id' do
        target_project = find_project!(params[:target_project_id])

        result = ::Ci::JobTokenScope::RemoveProjectService
          .new(user_project, current_user)
          .execute(target_project, :inbound)

        if result.success?
          no_content!
        elsif result.reason == :insufficient_permissions
          forbidden!(result.message)
        else
          bad_request!(result.message)
        end
      end
    end
  end
end
