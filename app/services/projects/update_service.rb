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

      new_branch = params[:default_branch]

      if project.repository.exists? && new_branch && new_branch != project.default_branch
        project.change_head(new_branch)
      end

      if project.update_attributes(params.except(:default_branch))
        if project.previous_changes.include?('path')
          project.rename_repo
        end
      else
        restore_attributes
        false
      end
    end

    private

    def restore_attributes
      project.path = project.path_was if project.errors.include?(:path)
      project.name = project.name_was if project.errors.include?(:name)
    end
  end
end
