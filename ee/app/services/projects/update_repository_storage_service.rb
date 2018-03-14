module Projects
  class UpdateRepositoryStorageService < BaseService
    include Gitlab::ShellAdapter

    def initialize(project)
      @project = project
    end

    def execute(new_repository_storage_key)
      result = mirror_repository(new_repository_storage_key)

      if project.wiki.repository_exists?
        result &&= mirror_repository(new_repository_storage_key, wiki: true)
      end

      if result
        mark_old_paths_for_archive

        project.update(repository_storage: new_repository_storage_key, repository_read_only: false)
      else
        project.update(repository_read_only: false)
      end
    end

    private

    def mirror_repository(new_storage_key, wiki: false)
      return false unless wait_for_pushes(wiki)

      repository = (wiki ? project.wiki.repository : project.repository).raw

      # Initialize a git repository on the target path
      gitlab_shell.create_repository(new_storage_key, repository.relative_path)
      new_repository = Gitlab::Git::Repository.new(new_storage_key,
                                                   repository.relative_path,
                                                   repository.gl_repository)

      new_repository.fetch_repository_as_mirror(repository)
    end

    def mark_old_paths_for_archive
      old_repository_storage_path = project.repository_storage_path
      new_project_path = moved_path(project.disk_path)

      # Notice that the block passed to `run_after_commit` will run with `project`
      # as its context
      project.run_after_commit do
        GitlabShellWorker.perform_async(:mv_repository,
                                        old_repository_storage_path,
                                        disk_path,
                                        new_project_path)

        if wiki.repository_exists?
          GitlabShellWorker.perform_async(:mv_repository,
                                          old_repository_storage_path,
                                          wiki.disk_path,
                                          "#{new_project_path}.wiki")
        end
      end
    end

    def moved_path(path)
      "#{path}+#{project.id}+moved+#{Time.now.to_i}"
    end

    def wait_for_pushes(wiki)
      reference_counter = project.reference_counter(wiki: wiki)

      # Try for 30 seconds, polling every 10
      3.times do
        return true if reference_counter.value == 0

        sleep 10
      end

      false
    end
  end
end
