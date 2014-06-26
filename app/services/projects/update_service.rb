module Projects
  class UpdateService < BaseService
    def execute
      # check that user is allowed to set specified visibility_level
      unless can?(current_user, :change_visibility_level, project) && Gitlab::VisibilityLevel.allowed_for?(current_user, params[:visibility_level])
        params[:visibility_level] = project.visibility_level
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
  end
end
