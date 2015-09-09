class RepositoryImportWorker
  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  sidekiq_options queue: :gitlab_shell

  def perform(project_id)
    project = Project.find(project_id)

    unless project.import_url == Project::UNKNOWN_IMPORT_URL
      import_result = gitlab_shell.send(:import_repository,
                               project.path_with_namespace,
                               project.import_url)
      return project.import_fail unless import_result
    else
      unless project.create_repository
        return project.import_fail
      end
    end

    data_import_result = case project.import_type
                         when 'github'
                           Gitlab::GithubImport::Importer.new(project).execute
                         when 'gitlab'
                           Gitlab::GitlabImport::Importer.new(project).execute
                         when 'bitbucket'
                           Gitlab::BitbucketImport::Importer.new(project).execute
                         when 'google_code'
                           Gitlab::GoogleCodeImport::Importer.new(project).execute
                         when 'fogbugz'
                           Gitlab::FogbugzImport::Importer.new(project).execute
                         else
                           true
                         end
    return project.import_fail unless data_import_result

    Gitlab::BitbucketImport::KeyDeleter.new(project).execute if project.import_type == 'bitbucket'

    project.import_finish
    project.save
    ProjectCacheWorker.perform_async(project.id)
  end
end
