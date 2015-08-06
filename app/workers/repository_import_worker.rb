class RepositoryImportWorker
  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  sidekiq_options queue: :gitlab_shell

  def perform(project_id)
    project = Project.find(project_id)

    import_result = gitlab_shell.send(:import_repository,
                               project.path_with_namespace,
                               project.import_url)
    return project.import_fail unless import_result

    data_import_result =  if project.import_type == 'github'
                            Gitlab::GithubImport::Importer.new(project).execute
                          elsif project.import_type == 'gitlab'
                            Gitlab::GitlabImport::Importer.new(project).execute
                          elsif project.import_type == 'bitbucket'
                            Gitlab::BitbucketImport::Importer.new(project).execute
                          elsif project.import_type == 'google_code'
                            Gitlab::GoogleCodeImport::Importer.new(project).execute
                          else
                            true
                          end
    return project.import_fail unless data_import_result

    project.import_finish
    project.save
    ProjectCacheWorker.perform_async(project.id)
    Gitlab::BitbucketImport::KeyDeleter.new(project).execute if project.import_type == 'bitbucket'
  end
end
