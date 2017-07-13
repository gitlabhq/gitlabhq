module Projects
  class UpdateService < BaseService
    def execute
      unless visibility_level_allowed?
        return error('New visibility level not allowed!')
      end

      if project.has_container_registry_tags?
        return error('Cannot rename project because it contains container registry tags!')
      end

      if changing_default_branch?
        project.change_head(new_branch)
      end

      if project.update_attributes(params.except(:default_branch))
        if project.previous_changes.include?('path')
          project.rename_repo
        else
          system_hook_service.execute_hooks_for(project, :update)
        end

        success
      else
        error('Project could not be updated!')
      end
    end

    private

    def visibility_level_allowed?
      # check that user is allowed to set specified visibility_level
      new_visibility = params[:visibility_level]

      if new_visibility && new_visibility.to_i != project.visibility_level
        unless can?(current_user, :change_visibility_level, project) &&
            Gitlab::VisibilityLevel.allowed_for?(current_user, new_visibility)

          deny_visibility_level(project, new_visibility)
          return false
        end
      end

      true
    end

    def changing_default_branch?
      new_branch = params[:default_branch]

      project.repository.exists? &&
        new_branch && new_branch != project.default_branch
    end
  end
end
