# frozen_string_literal: true

module Projects
  class ImportService < BaseService
    Error = Class.new(StandardError)
    PermissionError = Class.new(StandardError)

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

      download_lfs_objects

      import_data

      after_execute_hook

      success
    rescue Gitlab::UrlBlocker::BlockedUrlError => e
      Gitlab::ErrorTracking.track_exception(e, project_path: project.full_path, importer: project.import_type)

      error(s_("ImportProjects|Error importing repository %{project_safe_import_url} into %{project_full_path} - %{message}") % { project_safe_import_url: project.safe_import_url, project_full_path: project.full_path, message: e.message })
    rescue StandardError => e
      message = Projects::ImportErrorFilter.filter_message(e.message)

      Gitlab::ErrorTracking.track_exception(e, project_path: project.full_path, importer: project.import_type)

      error(s_("ImportProjects|Error importing repository %{project_safe_import_url} into %{project_full_path} - %{message}") % { project_safe_import_url: project.safe_import_url, project_full_path: project.full_path, message: message })
    end

    protected

    def extra_attributes_for_measurement
      {
        current_user: current_user&.name,
        project_full_path: project&.full_path,
        import_type: project&.import_type,
        file_path: project&.import_source
      }
    end

    private

    def after_execute_hook
      # Defined in EE::Projects::ImportService
    end

    def add_repository_to_project
      if project.external_import? && !unknown_url?
        begin
          Gitlab::UrlBlocker.validate!(project.import_url, ports: Project::VALID_IMPORT_PORTS)
        rescue Gitlab::UrlBlocker::BlockedUrlError => e
          raise e, s_("ImportProjects|Blocked import URL: %{message}") % { message: e.message }
        end
      end

      # We should skip the repository for a GitHub import or GitLab project import,
      # because these importers fetch the project repositories for us.
      return if importer_imports_repository?

      if unknown_url?
        # In this case, we only want to import issues, not a repository.
        create_repository
      elsif !project.repository_exists?
        import_repository
      end
    end

    def create_repository
      unless project.create_repository
        raise Error, s_('ImportProjects|The repository could not be created.')
      end
    end

    def import_repository
      refmap = importer_class.try(:refmap) if has_importer?

      if refmap
        project.ensure_repository
        project.repository.fetch_as_mirror(project.import_url, refmap: refmap)
      else
        project.repository.import_repository(project.import_url)
      end
    rescue ::Gitlab::Git::CommandError => e
      # Expire cache to prevent scenarios such as:
      # 1. First import failed, but the repo was imported successfully, so +exists?+ returns true
      # 2. Retried import, repo is broken or not imported but +exists?+ still returns true
      project.repository.expire_content_cache if project.repository_exists?

      raise Error, e.message
    end

    def download_lfs_objects
      # In this case, we only want to import issues
      return if unknown_url?

      # If it has its own repository importer, it has to implements its own lfs import download
      return if importer_imports_repository?

      return unless project.lfs_enabled?

      result = Projects::LfsPointers::LfsImportService.new(project).execute

      if result[:status] == :error
        # To avoid aborting the importing process, we silently fail
        # if any exception raises.
        Gitlab::AppLogger.error("The Lfs import process failed. #{result[:message]}")
      end
    end

    def import_data
      return unless has_importer?

      project.repository.expire_content_cache unless project.gitlab_project_import?

      unless importer.execute
        raise Error, s_('ImportProjects|The remote data could not be imported.')
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

    def importer_imports_repository?
      has_importer? && importer_class.try(:imports_repository?)
    end
  end
end

Projects::ImportService.prepend_mod_with('Projects::ImportService')

# Measurable should be at the bottom of the ancestor chain, so it will measure execution of EE::Projects::ImportService as well
Projects::ImportService.prepend(Measurable)
