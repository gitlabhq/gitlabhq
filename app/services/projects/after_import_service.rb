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
        repository.delete_all_refs_except(RESERVED_REF_PREFIXES)
      end

      # Right now we don't actually have a way to know if a project
      # import actually changed, so we increment the counter to avoid
      # causing GC to run every time.
      service.increment!
    rescue Projects::HousekeepingService::LeaseTaken => e
      Rails.logger.info( # rubocop:disable Gitlab/RailsLogger
        "Could not perform housekeeping for project #{@project.full_path} (#{@project.id}): #{e}")
    end

    private

    def repository
      @repository ||= @project.repository
    end
  end
end
