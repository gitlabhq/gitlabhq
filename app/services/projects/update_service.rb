module Projects
  class UpdateService < BaseService
    def execute
      # check that user is allowed to set specified visibility_level
      new_visibility = params[:visibility_level]
      if new_visibility
        if new_visibility.to_i != project.visibility_level
          unless can?(current_user, :change_visibility_level, project) &&
            Gitlab::VisibilityLevel.allowed_for?(current_user, new_visibility)
            deny_visibility_level(project, new_visibility)
            return project
          end
        end

        return false unless visibility_level_allowed?(new_visibility)
      end

      new_branch = params[:default_branch]

      if project.repository.exists? && new_branch && new_branch != project.default_branch
        project.change_head(new_branch)
      end

      if project.update_attributes(params.except(:default_branch))
        if project.previous_changes.include?('path')
          project.rename_repo
        end
      end
    end

    private

    def visibility_level_allowed?(level)
      return true if project.visibility_level_allowed?(level)

      level_name = Gitlab::VisibilityLevel.level_name(level)
      project.errors.add(
        :visibility_level,
        "#{level_name} could not be set as visibility level of this project - parent project settings are more restrictive"
      )

      false
    end
  end
end
