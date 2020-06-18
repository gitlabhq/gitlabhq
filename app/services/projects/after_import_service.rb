# frozen_string_literal: true

module Projects
  class AfterImportService
    RESERVED_REF_PREFIXES = Repository::RESERVED_REFS_NAMES.map { |n| File.join('refs', n, '/') }

    def initialize(project)
      @project = project
    end

    def execute
      service = Projects::HousekeepingService.new(@project)

      service.execute do
        import_failure_service.with_retry(action: 'delete_all_refs') do
          repository.delete_all_refs_except(RESERVED_REF_PREFIXES)
        end
      end

      # Right now we don't actually have a way to know if a project
      # import actually changed, so we increment the counter to avoid
      # causing GC to run every time.
      service.increment!
    rescue Projects::HousekeepingService::LeaseTaken => e
      Gitlab::Import::Logger.info(
        message: 'Project housekeeping failed',
        project_full_path: @project.full_path,
        project_id: @project.id,
        error: e.message
      )
    end

    private

    def import_failure_service
      Gitlab::ImportExport::ImportFailureService.new(@project)
    end

    def repository
      @project.repository
    end
  end
end
