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

      desc 'Fetch project groups allowlist for CI_JOB_TOKEN access settings.' do
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
      get ':id/job_token_scope/groups_allowlist' do
        authorize_admin_project

        groups_allowlist = ::Ci::JobToken::Scope.new(user_project).groups

        present paginate(groups_allowlist), with: Entities::BasicGroupDetails
      end

      desc 'Add target project to allowlist.' do
        failure [
          { code: 400, message: 'Bad Request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        success status: 201, model: Entities::BasicProjectDetails
        tags %w[projects_job_token_scope]
      end
      params do
        requires :id,
          allow_blank: false,
          desc: 'ID of user project',
          documentation: { example: 1 },
          type: Integer

        requires :target_project_id,
          allow_blank: false,
          desc: 'ID of target project',
          documentation: { example: 2 },
          type: Integer
      end
      post ':id/job_token_scope/allowlist' do
        authorize_admin_project

        target_project_id = declared_params(include_missing: false).fetch(:target_project_id)
        target_project = Project.find_by_id(target_project_id)
        break not_found!("target_project_id not found") if target_project.blank?

        result = ::Ci::JobTokenScope::AddProjectService
            .new(user_project, current_user)
            .execute(target_project, direction: :inbound)

        break bad_request!(result[:message]) if result.error?

        present result.payload[:project_link], with: Entities::ProjectScopeLink
      end

      desc 'Add target group to allowlist.' do
        failure [
          { code: 400, message: 'Bad Request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        success status: 201, model: Entities::BasicGroupDetails
        tags %w[projects_job_token_scope]
      end
      params do
        requires :id,
          allow_blank: false,
          desc: 'ID of user project',
          documentation: { example: 1 },
          type: Integer

        requires :target_group_id,
          allow_blank: false,
          desc: 'ID of target group',
          documentation: { example: 2 },
          type: Integer
      end
      post ':id/job_token_scope/groups_allowlist' do
        authorize_admin_project

        target_group_id = declared_params(include_missing: false).fetch(:target_group_id)
        target_group = Group.find_by_id(target_group_id)
        break not_found!("target_group_id not found") if target_group.blank?

        result = ::Ci::JobTokenScope::AddGroupService
            .new(user_project, current_user)
            .execute(target_group)

        break bad_request!(result[:message]) if result.error?

        present result.payload[:group_link], with: Entities::GroupScopeLink
      end

      desc 'Delete target group from allowlist.' do
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
        requires :id,
          allow_blank: false,
          desc: 'ID of user project',
          documentation: { example: 1 },
          type: Integer

        requires :target_group_id,
          allow_blank: false,
          desc: 'ID of the group to be removed from the allowlist',
          documentation: { example: 2 },
          type: Integer
      end
      delete ':id/job_token_scope/groups_allowlist/:target_group_id' do
        target_group_id = declared_params(include_missing: false).fetch(:target_group_id)
        target_group = Group.find_by_id(target_group_id)
        break not_found!("target_group_id not found") if target_group.blank?

        result = ::Ci::JobTokenScope::RemoveGroupService
          .new(user_project, current_user)
          .execute(target_group)

        if result.success?
          no_content!
        elsif result.reason == :insufficient_permissions
          forbidden!(result.message)
        else
          bad_request!(result.message)
        end
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
        requires :id,
          allow_blank: false,
          desc: 'ID of user project',
          documentation: { example: 1 },
          type: Integer

        requires :target_project_id,
          allow_blank: false,
          desc: 'ID of the project to be removed from the allowlist',
          documentation: { example: 2 },
          type: Integer
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
