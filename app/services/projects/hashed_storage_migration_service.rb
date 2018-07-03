module Projects
  class HashedStorageMigrationService < BaseService
    attr_reader :logger, :path_before_rename

    def initialize(project, logger: nil, path_before_rename: nil)
      @project = project
      @path_before_rename = path_before_rename
      @logger = logger || Rails.logger
    end

    def execute
      # Migrate repository from Legacy to Hashed Storage
      unless project.hashed_storage?(:repository)
        return unless HashedStorage::MigrateRepositoryService.new(project, logger: logger, path_before_rename: path_before_rename).execute
      end

      # Migrate attachments from Legacy to Hashed Storage
      unless project.hashed_storage?(:attachments)
        HashedStorage::MigrateAttachmentsService.new(project, logger: logger, path_before_rename: path_before_rename).execute
      end
    end
  end
end
