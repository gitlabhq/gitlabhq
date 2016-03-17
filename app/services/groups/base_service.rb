module Groups
  class BaseService
    attr_accessor :group, :current_user, :params

    def initialize(group, user, params = {})
      @group, @current_user, @params = group, user, params.dup
    end

    private

    def visibility_allowed_for_user?(level)
      allowed_by_user  = Gitlab::VisibilityLevel.allowed_for?(current_user, level)
      @group.errors.add(:visibility_level, "You are not authorized to set this permission level.") unless allowed_by_user
      allowed_by_user
    end

    def visibility_allowed_for_project?(level)
      projects_visibility = group.projects.pluck(:visibility_level)

      allowed_by_projects = !projects_visibility.any? { |project_visibility| level.to_i < project_visibility }
      @group.errors.add(:visibility_level, "Cannot be changed. There are projects with higher visibility permissions.") unless allowed_by_projects
      allowed_by_projects
    end
  end
end
