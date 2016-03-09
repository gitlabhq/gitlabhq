#Checks visibility level permission check before updating a group
#Do not allow to put Group visibility level smaller than its projects
#Do not allow unauthorized permission levels

module Groups
  class UpdateService < Groups::BaseService
    def execute
      visibility_level_allowed?(params[:visibility_level]) ? group.update_attributes(params) : false
    end

    private

    def visibility_level_allowed?(level)
      return true unless level.present?

      allowed_by_projects = visibility_by_project(level)
      allowed_by_user     = visibility_by_user(level)

      allowed_by_projects && allowed_by_user
    end

    def visibility_by_project(level)
      projects_visibility = group.projects.pluck(:visibility_level)

      allowed_by_projects = !projects_visibility.any?{|project_visibility| level.to_i < project_visibility }
      add_error_message("Cannot be changed. There are projects with higher visibility permissions.") unless allowed_by_projects
      allowed_by_projects
    end

    def visibility_by_user(level)
      allowed_by_user  = Gitlab::VisibilityLevel.allowed_for?(current_user, level)
      add_error_message("You are not authorized to set this permission level.") unless allowed_by_user
      allowed_by_user
    end

    def add_error_message(message)
      level_name = Gitlab::VisibilityLevel.level_name(params[:visibility_level])
      group.errors.add(:visibility_level, message)
    end
  end
end



