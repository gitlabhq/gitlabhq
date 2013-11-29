module Projects
  class UpdateContext < BaseContext
    def execute(role = :default)
      params[:project].delete(:namespace_id)
      params[:project].delete(:public) unless can?(current_user, :change_public_mode, project)
      new_branch = params[:project].delete(:default_branch)

      if project.repository.exists? && new_branch != project.repository.root_ref
        GitlabShellWorker.perform_async(
          :update_repository_head,
          project.path_with_namespace,
          new_branch
        )
      end

      project.update_attributes(params[:project], as: role)
    end
  end
end
