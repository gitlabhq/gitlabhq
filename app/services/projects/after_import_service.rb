module Projects
  class AfterImportService
    RESERVED_REFS_REGEXP =
      %r{\Arefs/(?:#{Regexp.union(*Repository::RESERVED_REFS_NAMES)})/}

    def initialize(project)
      @project = project
    end

    def execute
      Projects::HousekeepingService.new(@project).execute do
        repository.delete_refs(*garbage_refs)
      end
    rescue Projects::HousekeepingService::LeaseTaken => e
      Rails.logger.info(
        "Could not perform housekeeping for project #{@project.full_path} (#{@project.id}): #{e}")
    end

    private

    def garbage_refs
      @garbage_refs ||= repository.all_ref_names_except(RESERVED_REFS_REGEXP)
    end

    def repository
      @repository ||= @project.repository
    end
  end
end
