module Projects
  class UpdateService < BaseService
    def execute
      # Repository size limit comes as MB from the view
      limit = params.delete(:repository_size_limit)
      project.repository_size_limit = Gitlab::Utils.try_megabytes_to_bytes(limit) if limit

      unless visibility_level_allowed?
        return error('New visibility level not allowed!')
      end

      if changing_storage_size?
        project.change_repository_storage(params.delete(:repository_storage))
      end

      if renaming_project_with_container_registry_tags?
        return error('Cannot rename project because it contains container registry tags!')
      end

      if changing_default_branch?
        project.change_head(params[:default_branch])
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

    def changing_storage_size?
      new_repository_storage = params[:repository_storage]

      new_repository_storage && project.repository.exists? &&
        can?(current_user, :change_repository_storage, project)
    end

    def renaming_project_with_container_registry_tags?
      new_path = params[:path]

      new_path && new_path != project.path &&
        project.has_container_registry_tags?
    end

    def changing_default_branch?
      new_branch = params[:default_branch]

      new_branch && project.repository.exists? &&
        new_branch != project.default_branch
    end
  end
end
