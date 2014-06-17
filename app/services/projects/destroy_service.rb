module Projects
  class DestroyService < BaseService
    def execute
      return false unless can?(current_user, :remove_project, project)

      project.team.truncate
      project.repository.expire_cache unless project.empty_repo?

      if project.destroy
        GitlabShellWorker.perform_async(
          :remove_repository,
          project.path_with_namespace
        )

        GitlabShellWorker.perform_async(
          :remove_repository,
          project.path_with_namespace + ".wiki"
        )

        project.satellite.destroy

        log_info("Project \"#{project.name}\" was removed")
        system_hook_service.execute_hooks_for(project, :destroy)
        true
      end
    end
  end
end
