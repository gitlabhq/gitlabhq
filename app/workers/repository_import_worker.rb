class RepositoryImportWorker
  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  sidekiq_options queue: :gitlab_shell

  def perform(project_id)
    project = Project.find(project_id)

    if project.import_url == Project::UNKNOWN_IMPORT_URL
      # In this case, we only want to import issues, not a repository.
      unless project.create_repository
        project.update(import_error: "The repository could not be created.")
        project.import_fail
        return
      end
    else
      begin
        gitlab_shell.import_repository(project.path_with_namespace, project.import_url)
      rescue Gitlab::Shell::Error => e
        project.update(import_error: e.message)
        project.import_fail
        return
      end
    end

    data_import_result =
      case project.import_type
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

    unless data_import_result
      project.update(import_error: "The remote issue data could not be imported.")
      project.import_fail
      return
    end

    if project.import_type == 'bitbucket'
      Gitlab::BitbucketImport::KeyDeleter.new(project).execute
    end

    project.import_finish
  end
end
