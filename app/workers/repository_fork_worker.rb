# frozen_string_literal: true

class RepositoryForkWorker
  include ApplicationWorker
  include Gitlab::ShellAdapter
  include ProjectStartImport
  include ProjectImportOptions

  def perform(*args)
    target_project_id = args.shift
    target_project = Project.find(target_project_id)

    source_project = target_project.forked_from_project
    unless source_project
      return target_project.mark_import_as_failed('Source project cannot be found.')
    end

    fork_repository(target_project, source_project.repository_storage, source_project.disk_path)
  end

  private

  def fork_repository(target_project, source_repository_storage_name, source_disk_path)
    return unless start_fork(target_project)

    Gitlab::Metrics.add_event(:fork_repository)

    result = gitlab_shell.fork_repository(source_repository_storage_name, source_disk_path,
                                          target_project.repository_storage, target_project.disk_path)
    raise "Unable to fork project #{target_project.id} for repository #{source_disk_path} -> #{target_project.disk_path}" unless result

    target_project.after_import
  end

  def start_fork(project)
    return true if start(project)

    Rails.logger.info("Project #{project.full_path} was in inconsistent state (#{project.import_status}) while forking.")
    false
  end
end
