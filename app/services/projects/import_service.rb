module Projects
  class ImportService < BaseService
    include Gitlab::ShellAdapter

    Error = Class.new(StandardError)

    # Returns true if this importer is supposed to perform its work in the
    # background.
    #
    # This method will only return `true` if async importing is explicitly
    # supported by an importer class (`Gitlab::GithubImport::ParallelImporter`
    # for example).
    def async?
      has_importer? && !!importer_class.try(:async?)
    end

    def execute
      add_repository_to_project

      import_data

      success
    rescue => e
      error("Error importing repository #{project.import_url} into #{project.full_path} - #{e.message}")
    end

    private

    def add_repository_to_project
      if project.external_import? && !unknown_url?
        begin
          Gitlab::UrlBlocker.validate!(project.import_url, valid_ports: Project::VALID_IMPORT_PORTS)
        rescue Gitlab::UrlBlocker::BlockedUrlError => e
          raise Error, "Blocked import URL: #{e.message}"
        end
      end

      # We should skip the repository for a GitHub import or GitLab project import,
      # because these importers fetch the project repositories for us.
      return if has_importer? && importer_class.try(:imports_repository?)

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
      begin
        refmap = importer_class.try(:refmap) if has_importer?

        if refmap
          project.ensure_repository
          project.repository.fetch_as_mirror(project.import_url, refmap: refmap)
        else
          gitlab_shell.import_repository(project.repository_storage, project.disk_path, project.import_url)
        end
      rescue Gitlab::Shell::Error, Gitlab::Git::RepositoryMirroring::RemoteError => e
        # Expire cache to prevent scenarios such as:
        # 1. First import failed, but the repo was imported successfully, so +exists?+ returns true
        # 2. Retried import, repo is broken or not imported but +exists?+ still returns true
        project.repository.expire_content_cache if project.repository_exists?

        raise Error, e.message
      end
    end

    def import_data
      return unless has_importer?

      project.repository.expire_content_cache unless project.gitlab_project_import?

      unless importer.execute
        raise Error, 'The remote data could not be imported.'
      end
    end

    def importer_class
      @importer_class ||= Gitlab::ImportSources.importer(project.import_type)
    end

    def has_importer?
      Gitlab::ImportSources.importer_names.include?(project.import_type)
    end

    def importer
      importer_class.new(project)
    end

    def unknown_url?
      project.import_url == Project::UNKNOWN_IMPORT_URL
    end
  end
end
