module Projects
  class ImportService < BaseService
    include Gitlab::ShellAdapter

    class Error < StandardError; end

    ALLOWED_TYPES = [
      'bitbucket',
      'fogbugz',
      'gitlab',
      'github',
      'google_code'
    ]

    def execute
      if unknown_url?
        # In this case, we only want to import issues, not a repository.
        create_repository
      else
        import_repository
      end

      import_data

      success
    rescue Error => e
      error(e.message)
    end

    private

    def create_repository
      unless project.create_repository
        raise Error, 'The repository could not be created.'
      end
    end

    def import_repository
      begin
        gitlab_shell.import_repository(project.path_with_namespace, project.import_url)
      rescue Gitlab::Shell::Error => e
        raise Error, e.message
      end
    end

    def import_data
      return unless has_importer?

      unless importer.execute
        raise Error, 'The remote data could not be imported.'
      end
    end

    def has_importer?
      ALLOWED_TYPES.include?(project.import_type)
    end

    def importer
      class_name = "Gitlab::#{project.import_type.camelize}Import::Importer"
      class_name.constantize.new(project)
    end

    def unknown_url?
      project.import_url == Project::UNKNOWN_IMPORT_URL
    end
  end
end
