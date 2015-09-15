class RepositoryForkWorker
  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  sidekiq_options queue: :gitlab_shell

  def perform(project_id, source_path, target_path)
    project = Project.find_by_id(project_id)

    unless project.present?
      logger.error("Project #{project_id} no longer exists!")
      return
    end

    result = gitlab_shell.fork_repository(source_path, target_path)

    unless result
      logger.error("Unable to fork project #{project_id} for repository #{source_path} -> #{target_path}")
      project.import_fail
      project.save
      return
    end

    if project.valid_repo?
      ProjectCacheWorker.perform_async(project.id)
      project.import_finish
    else
      project.import_fail
      logger.error("Project #{id} had an invalid repository after fork")
    end

    project.save
  end
end
