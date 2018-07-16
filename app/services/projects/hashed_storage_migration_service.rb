module Projects
  class HashedStorageMigrationService < BaseService
    attr_reader :logger, :old_path

    def initialize(project, old_path, logger: nil)
      @project = project
      @old_path = old_path
      @logger = logger || Rails.logger
    end

    def execute
      # Migrate repository from Legacy to Hashed Storage
      unless project.hashed_storage?(:repository)
        return unless HashedStorage::MigrateRepositoryService.new(project, old_path, logger: logger).execute
      end

      # Migrate attachments from Legacy to Hashed Storage
      unless project.hashed_storage?(:attachments)
        HashedStorage::MigrateAttachmentsService.new(project, old_path, logger: logger).execute
      end
    end
  end
end
