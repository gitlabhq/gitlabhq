class RepositoryForkWorker
  ForkError = Class.new(StandardError)

  include Sidekiq::Worker
  include Gitlab::ShellAdapter
  include DedicatedSidekiqQueue

  def perform(project_id, forked_from_repository_storage_path, source_path, target_path)
    Gitlab::Metrics.add_event(:fork_repository,
                              source_path: source_path,
                              target_path: target_path)

    project = Project.find(project_id)
    project.import_start

    result = gitlab_shell.fork_repository(forked_from_repository_storage_path, source_path,
                                          project.repository_storage_path, target_path)
    raise ForkError, "Unable to fork project #{project_id} for repository #{source_path} -> #{target_path}" unless result

    project.repository.after_import
    raise ForkError, "Project #{project_id} had an invalid repository after fork" unless project.valid_repo?

    project.import_finish
  rescue ForkError => ex
    fail_fork(project, ex.message)
    raise
  rescue => ex
    return unless project

    fail_fork(project, ex.message)
    raise ForkError, "#{ex.class} #{ex.message}"
  end

  private

  def fail_fork(project, message)
    Rails.logger.error(message)
    project.mark_import_as_failed(message)
  end
end
