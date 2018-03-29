# Gitaly issue: https://gitlab.com/gitlab-org/gitaly/issues/1110
class RepositoryForkWorker
  include ApplicationWorker
  include Gitlab::ShellAdapter
  include ProjectStartImport
  include ProjectImportOptions

  def perform(project_id, forked_from_repository_storage_path, source_disk_path)
    project = Project.find(project_id)

    return unless start_fork(project)

    Gitlab::Metrics.add_event(:fork_repository,
                              source_path: source_disk_path,
                              target_path: project.disk_path)

    result = gitlab_shell.fork_repository(forked_from_repository_storage_path, source_disk_path,
                                          project.repository_storage_path, project.disk_path)
    raise "Unable to fork project #{project_id} for repository #{source_disk_path} -> #{project.disk_path}" unless result

    project.after_import
  end

  private

  def start_fork(project)
    return true if start(project)

    Rails.logger.info("Project #{project.full_path} was in inconsistent state (#{project.import_status}) while forking.")
    false
  end
end
