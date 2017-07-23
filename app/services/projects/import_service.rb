module Projects
  class ImportService < BaseService
    include Gitlab::ShellAdapter

    Error = Class.new(StandardError)

    def execute
      add_repository_to_project unless project.gitlab_project_import?

      import_data

      success
    rescue => e
      error("Error importing repository #{project.import_url} into #{project.path_with_namespace} - #{e.message}")
    end

    private

    def add_repository_to_project
      if unknown_url?
        # In this case, we only want to import issues, not a repository.
        create_repository
      elsif !project.repository_exists?
        import_repository
      end
    end

    def create_repository
      unless project.create_repository
        raise Error, 'The repository could not be created.'
      end
    end

    def import_repository
      raise Error, 'Blocked import URL.' if Gitlab::UrlBlocker.blocked_url?(project.import_url)

      begin
        if project.github_import? || project.gitea_import?
          fetch_repository
        else
          clone_repository
        end
      rescue Gitlab::Shell::Error => e
        # Expire cache to prevent scenarios such as:
        # 1. First import failed, but the repo was imported successfully, so +exists?+ returns true
        # 2. Retried import, repo is broken or not imported but +exists?+ still returns true
        project.repository.expire_content_cache if project.repository_exists?

        raise Error, e.message
      end
    end

    def clone_repository
      gitlab_shell.import_repository(project.repository_storage_path, project.path_with_namespace, project.import_url)
    end

    def fetch_repository
      project.create_repository
      project.repository.add_remote(project.import_type, project.import_url)
      project.repository.set_remote_as_mirror(project.import_type)
      project.repository.fetch_remote(project.import_type, forced: true)
    end

    def import_data
      return unless has_importer?

      project.repository.expire_content_cache unless project.gitlab_project_import?

      unless importer.execute
        raise Error, 'The remote data could not be imported.'
      end
    end

    def has_importer?
      Gitlab::ImportSources.importer_names.include?(project.import_type)
    end

    def importer
      Gitlab::ImportSources.importer(project.import_type).new(project)
    end

    def unknown_url?
      project.import_url == Project::UNKNOWN_IMPORT_URL
    end
  end
end
