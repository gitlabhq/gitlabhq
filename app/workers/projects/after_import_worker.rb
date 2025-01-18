# frozen_string_literal: true

module Projects
  class AfterImportWorker
    include ApplicationWorker

    RESERVED_REF_PREFIXES = Repository::RESERVED_REFS_NAMES.map { |n| File.join('refs', n, '/') }

    data_consistency :always
    idempotent!
    urgency :low
    feature_category :importers

    def perform(project_id)
      @project = Project.find(project_id)

      service = ::Repositories::HousekeepingService.new(@project)

      service.execute do
        import_failure_service.with_retry(action: 'delete_all_refs') do
          repository.delete_all_refs_except(RESERVED_REF_PREFIXES)
        end
      end

      # Right now we don't actually have a way to know if a project
      # import actually changed, so we increment the counter to avoid
      # causing GC to run every time.
      service.increment!
    rescue ::Repositories::HousekeepingService::LeaseTaken => e
      ::Import::Framework::Logger.info(
        message: 'Project housekeeping failed',
        project_full_path: @project.full_path,
        project_id: @project.id,
        'exception.message' => e.message
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
