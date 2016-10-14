module Projects
  class ImportService < BaseService
    include Gitlab::ShellAdapter

    class Error < StandardError; end

    ALLOWED_TYPES = [
      'bitbucket',
      'fogbugz',
      'gitlab',
      'github',
      'google_code',
      'gitlab_project'
    ]

    def execute
      add_repository_to_project unless project.gitlab_project_import?

      import_data

      success
    rescue => e
      error(e.message)
    end

    private

    def add_repository_to_project
      if unknown_url?
        # In this case, we only want to import issues, not a repository.
        create_repository
      else
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
        gitlab_shell.import_repository(project.repository_storage_path, project.path_with_namespace, project.import_url)
      rescue => e
        # Expire cache to prevent scenarios such as:
        # 1. First import failed, but the repo was imported successfully, so +exists?+ returns true
        # 2. Retried import, repo is broken or not imported but +exists?+ still returns true
        project.repository.before_import if project.repository_exists?

        raise Error,  "Error importing repository #{project.import_url} into #{project.path_with_namespace} - #{e.message}"
      end
    end

    def import_data
      return unless has_importer?

      project.repository.before_import unless project.gitlab_project_import?

      unless importer.execute
        raise Error, 'The remote data could not be imported.'
      end
    end

    def has_importer?
      ALLOWED_TYPES.include?(project.import_type)
    end

    def importer
      return Gitlab::ImportExport::Importer.new(project) if @project.gitlab_project_import?

      class_name = "Gitlab::#{project.import_type.camelize}Import::Importer"
      class_name.constantize.new(project)
    end

    def unknown_url?
      project.import_url == Project::UNKNOWN_IMPORT_URL
    end
  end
end
