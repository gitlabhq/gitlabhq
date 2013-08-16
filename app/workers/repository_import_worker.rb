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
      project.imported = true
      project.save
      project.satellite.create unless project.satellite.exists?
      project.discover_default_branch
    else
      project.imported = false
    end
  end
end
