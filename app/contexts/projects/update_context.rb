module Projects
  class UpdateContext < BaseContext
    def execute(role = :default)
      params[:project].delete(:namespace_id)
      # check that user is allowed to set specified visibility_level
      unless can?(current_user, :change_visibility_level, project) && Gitlab::VisibilityLevel.allowed_for?(current_user, params[:project][:visibility_level])
        params[:project].delete(:visibility_level)
      end

      new_branch = params[:project].delete(:default_branch)

      if project.repository.exists? && new_branch != project.default_branch
        GitlabShellWorker.perform_async(
          :update_repository_head,
          project.path_with_namespace,
          new_branch
        )

        project.reload_default_branch
      end

      project.update_attributes(params[:project], as: role)
    end
  end
end
