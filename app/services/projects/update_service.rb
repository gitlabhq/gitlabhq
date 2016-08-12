module Projects
  class UpdateService < BaseService
    def execute
      # check that user is allowed to set specified visibility_level
      new_visibility = params[:visibility_level]

      if new_visibility && new_visibility.to_i != project.visibility_level
        unless can?(current_user, :change_visibility_level, project) &&
          Gitlab::VisibilityLevel.allowed_for?(current_user, new_visibility)

          deny_visibility_level(project, new_visibility)
          return project
        end
      end

      new_branch = params.delete(:default_branch)
      new_repository_storage = params.delete(:repository_storage)

      if project.repository.exists?
        if new_branch && new_branch != project.default_branch
          project.change_head(new_branch)
        end

        if new_repository_storage && can?(current_user, :change_repository_storage, project)
          project.change_repository_storage(new_repository_storage)
        end
      end

      if project.update_attributes(params)
        if project.previous_changes.include?('path')
          project.rename_repo
        end
      end
    end
  end
end
