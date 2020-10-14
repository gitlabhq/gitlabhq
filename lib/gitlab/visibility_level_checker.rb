# frozen_string_literal: true

# Gitlab::VisibilityLevelChecker verifies that:
#   - Current @project.visibility_level is not restricted
#   - Override visibility param is not restricted
#     - @see https://docs.gitlab.com/ee/api/project_import_export.html#import-a-file
#
# @param current_user [User] Current user object to verify visibility level against
# @param project [Project] Current project that is being created/imported
# @param project_params [Hash] Supplementary project params (e.g. import
# params containing visibility override)
#
# @example
#   user = User.find(2)
#   project = Project.last
#   project_params = {:import_data=>{:data=>{:override_params=>{"visibility"=>"public"}}}}
#   level_checker = Gitlab::VisibilityLevelChecker.new(user, project, project_params: project_params)
#
#   project_visibility = level_checker.level_restricted?
#   => #<Gitlab::VisibilityEvaluationResult:0x00007fbe16ee33c0 @restricted=true, @visibility_level=20>
#
#   if project_visibility.restricted?
#     deny_visibility_level(project, project_visibility.visibility_level)
#   end
#
# @return [VisibilityEvaluationResult] Visibility evaluation result. Responds to:
# #restricted - boolean indicating if level is restricted
# #visibility_level - integer of restricted visibility level
#
module Gitlab
  class VisibilityLevelChecker
    def initialize(current_user, project, project_params: {})
      @current_user   = current_user
      @project        = project
      @project_params = project_params
    end

    def level_restricted?
      return VisibilityEvaluationResult.new(true, override_visibility_level_value) if override_visibility_restricted?
      return VisibilityEvaluationResult.new(true, project.visibility_level) if project_visibility_restricted?

      VisibilityEvaluationResult.new(false, nil)
    end

    private

    attr_reader :current_user, :project, :project_params

    def override_visibility_restricted?
      return unless import_data
      return unless override_visibility_level
      return if Gitlab::VisibilityLevel.allowed_for?(current_user, override_visibility_level_value)

      true
    end

    def project_visibility_restricted?
      return if Gitlab::VisibilityLevel.allowed_for?(current_user, project.visibility_level)

      true
    end

    def import_data
      @import_data ||= project_params[:import_data]
    end

    def override_visibility_level
      @override_visibility_level ||= import_data.deep_symbolize_keys.dig(:data, :override_params, :visibility)
    end

    def override_visibility_level_value
      @override_visibility_level_value ||= Gitlab::VisibilityLevel.level_value(override_visibility_level)
    end
  end

  class VisibilityEvaluationResult
    attr_reader :visibility_level

    def initialize(restricted, visibility_level)
      @restricted = restricted
      @visibility_level = visibility_level
    end

    def restricted?
      @restricted
    end
  end
end
