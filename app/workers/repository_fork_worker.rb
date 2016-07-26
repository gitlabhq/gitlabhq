class RepositoryForkWorker
  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  sidekiq_options queue: :gitlab_shell

  def perform(project_id, forked_from_repository_storage_path, source_path, target_path)
    project = Project.find_by_id(project_id)

    unless project.present?
      logger.error("Project #{project_id} no longer exists!")
      return
    end

    result = gitlab_shell.fork_repository(forked_from_repository_storage_path, source_path,
                                          project.repository_storage_path, target_path)
    unless result
      logger.error("Unable to fork project #{project_id} for repository #{source_path} -> #{target_path}")
      project.mark_import_as_failed('The project could not be forked.')
      return
    end

    project.repository.after_import

    unless project.valid_repo?
      logger.error("Project #{project_id} had an invalid repository after fork")
      project.mark_import_as_failed('The forked repository is invalid.')
      return
    end

    project.import_finish
  end
end
