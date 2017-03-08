module Projects
  class UpdateRepositoryStorageService < BaseService
    include Gitlab::ShellAdapter

    def initialize(project)
      @project = project
    end

    def execute(new_repository_storage_key)
      new_storage_path = Gitlab.config.repositories.storages[new_repository_storage_key]
      result = move_storage(project.path_with_namespace, new_storage_path)

      if project.wiki.repository_exists?
        result &&= move_storage("#{project.path_with_namespace}.wiki", new_storage_path)
      end

      if result
        mark_old_paths_for_archive

        project.update(repository_storage: new_repository_storage_key, repository_read_only: false)
      else
        project.update(repository_read_only: false)
      end
    end

    private

    def move_storage(project_path, new_storage_path)
      gitlab_shell.mv_storage(project.repository_storage_path, project_path, new_storage_path)
    end

    def mark_old_paths_for_archive
      old_repository_storage_path = project.repository_storage_path
      new_project_path = moved_path(project.path_with_namespace)

      # Notice that the block passed to `run_after_commit` will run with `project`
      # as its context
      project.run_after_commit do
        GitlabShellWorker.perform_async(:mv_repository,
                                        old_repository_storage_path,
                                        path_with_namespace,
                                        new_project_path)

        if wiki.repository_exists?
          GitlabShellWorker.perform_async(:mv_repository,
                                          old_repository_storage_path,
                                          "#{path_with_namespace}.wiki",
                                          "#{new_project_path}.wiki")
        end
      end
    end

    def moved_path(path)
      "#{path}+#{project.id}+moved+#{Time.now.to_i}"
    end
  end
end
