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

      new_path = params[:path]
      status = true

      if new_path && new_path != project.path
        status = project.rename_repo(new_path)
      end

      project.update_attributes(params.except(:default_branch))
      status
    rescue RuntimeError
    end
  end
end
