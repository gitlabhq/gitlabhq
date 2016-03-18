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
      project.update(import_error: "The project could not be forked.")
      project.import_fail
      return
    end

    unless project.valid_repo?
      logger.error("Project #{id} had an invalid repository after fork")
      project.update(import_error: "The forked repository is invalid.")
      project.import_fail
      return
    end

    project.repository.after_import
    project.import_finish
  end
end
