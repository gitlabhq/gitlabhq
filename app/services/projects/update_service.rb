module Projects
  class UpdateService < BaseService
    include UpdateVisibilityLevel

    def execute
      unless valid_visibility_level_change?(project, params[:visibility_level])
        return error('New visibility level not allowed!')
      end

      if renaming_project_with_container_registry_tags?
        return error('Cannot rename project because it contains container registry tags!')
      end

      if changing_default_branch?
        return error("Could not set the default branch") unless project.change_head(params[:default_branch])
      end

      if project.update_attributes(params.except(:default_branch))
        if project.previous_changes.include?('path')
          project.rename_repo
        else
          system_hook_service.execute_hooks_for(project, :update)
        end

        success
      else
        model_errors = project.errors.full_messages.to_sentence
        error_message = model_errors.presence || 'Project could not be updated!'

        error(error_message)
      end
    end

    private

    def renaming_project_with_container_registry_tags?
      new_path = params[:path]

      new_path && new_path != project.path &&
        project.has_container_registry_tags?
    end

    def changing_default_branch?
      new_branch = params[:default_branch]

      project.repository.exists? &&
        new_branch && new_branch != project.default_branch
    end
  end
end
