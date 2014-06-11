class RepositoryImportWorker
  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  sidekiq_options queue: :gitlab_shell

  def perform(project_id)
    project = Project.find(project_id)
    result = gitlab_shell.send(:import_repository,
                               project.path_with_namespace,
                               project.import_url)

    if result
      project.import_finish
      project.save
      project.satellite.create unless project.satellite.exists?
      project.update_repository_size
    else
      project.import_fail
    end
  end
end