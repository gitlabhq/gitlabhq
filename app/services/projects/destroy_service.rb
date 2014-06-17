module Projects
  class UpdateService < BaseService
    def execute(role = :default)
      return false unless can?(current_user, :remove_project, project)

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
      end
    end
  end
end
