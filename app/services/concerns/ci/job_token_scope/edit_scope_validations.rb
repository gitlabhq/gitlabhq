# frozen_string_literal: true

module Ci
  module JobTokenScope
    module EditScopeValidations
      ValidationError = Class.new(StandardError)

      TARGET_PROJECT_UNAUTHORIZED_OR_UNFOUND = "The target_project that you are attempting to access does " \
          "not exist or you don't have permission to perform this action"

      def validate_edit!(source_project, target_project, current_user)
        unless source_project.ci_job_token_scope_enabled?
          raise ValidationError, "Job token scope is disabled for this project"
        end

        unless can?(current_user, :admin_project, source_project)
          raise ValidationError, "Insufficient permissions to modify the job token scope"
        end

        unless can?(current_user, :read_project, target_project)
          raise ValidationError, TARGET_PROJECT_UNAUTHORIZED_OR_UNFOUND
        end
      end
    end
  end
end
