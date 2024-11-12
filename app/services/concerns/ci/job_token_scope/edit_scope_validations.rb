# frozen_string_literal: true

module Ci
  module JobTokenScope
    module EditScopeValidations
      ValidationError = Class.new(StandardError)
      NotFoundError = Class.new(StandardError)

      TARGET_PROJECT_UNAUTHORIZED_OR_UNFOUND = "The target_project that you are attempting to access does " \
          "not exist or you don't have permission to perform this action"

      TARGET_GROUP_UNAUTHORIZED_OR_UNFOUND = "The target_group that you are attempting to access does " \
          "not exist or you don't have permission to perform this action"

      TARGET_DOES_NOT_EXIST = 'The group or project does not exist.'

      def validate_source_project_and_target_project_access!(source_project, target_project, current_user)
        unless can?(current_user, :admin_project, source_project)
          raise ValidationError, "Insufficient permissions to modify the job token scope"
        end

        unless can?(current_user, :read_project, target_project)
          raise ValidationError, TARGET_PROJECT_UNAUTHORIZED_OR_UNFOUND
        end
      end

      def validate_source_project_and_target_group_access!(source_project, target_group, current_user)
        unless can?(current_user, :admin_project, source_project)
          raise ValidationError, "Insufficient permissions to modify the job token scope"
        end

        raise ValidationError, TARGET_GROUP_UNAUTHORIZED_OR_UNFOUND unless can?(current_user, :read_group,
          target_group)
      end

      def validate_group_remove!(source_project, current_user)
        unless can?(current_user, :admin_project, source_project)
          raise ValidationError, "Insufficient permissions to modify the job token scope"
        end
      end

      def validate_target_exists!(target)
        raise NotFoundError, TARGET_DOES_NOT_EXIST if target.nil?
      end
    end
  end
end
