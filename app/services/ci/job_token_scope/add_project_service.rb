# frozen_string_literal: true

module Ci
  module JobTokenScope
    class AddProjectService < ::BaseService
      TARGET_PROJECT_UNAUTHORIZED_OR_UNFOUND = "The target_project that you are attempting to access does " \
          "not exist or you don't have permission to perform this action"

      def execute(target_project)
        if error_response = validation_error(target_project)
          return error_response
        end

        link = add_project!(target_project)
        ServiceResponse.success(payload: { project_link: link })

      rescue ActiveRecord::RecordNotUnique
        ServiceResponse.error(message: "Target project is already in the job token scope")
      rescue ActiveRecord::RecordInvalid => e
        ServiceResponse.error(message: e.message)
      end

      private

      def validation_error(target_project)
        unless project.ci_job_token_scope_enabled?
          return ServiceResponse.error(message: "Job token scope is disabled for this project")
        end

        unless can?(current_user, :admin_project, project)
          return ServiceResponse.error(message: "Insufficient permissions to modify the job token scope")
        end

        unless target_project
          return ServiceResponse.error(message: TARGET_PROJECT_UNAUTHORIZED_OR_UNFOUND)
        end

        unless can?(current_user, :read_project, target_project)
          return ServiceResponse.error(message: TARGET_PROJECT_UNAUTHORIZED_OR_UNFOUND)
        end

        nil
      end

      def add_project!(target_project)
        ::Ci::JobToken::ProjectScopeLink.create!(
          source_project: project,
          target_project: target_project,
          added_by: current_user
        )
      end
    end
  end
end
