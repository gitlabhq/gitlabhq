module Projects
  class HashedStorageMigrationService < BaseService
    attr_reader :logger

    def initialize(project, logger = nil)
      @project = project
      @logger = logger || Rails.logger
    end

    def execute
      # Migrate repository from Legacy to Hashed Storage
      unless project.hashed_storage?(:repository)
        return unless HashedStorage::MigrateRepositoryService.new(project, logger).execute
      end

      # Migrate attachments from Legacy to Hashed Storage
      unless project.hashed_storage?(:attachments)
        HashedStorage::MigrateAttachmentsService.new(project, logger).execute
      end
    end
  end
end
