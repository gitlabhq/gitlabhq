module Projects
  class HashedStorageMigrationService < BaseService
    attr_reader :options

    def initialize(project, options = {})
      @project = project
      @options = options
      @options[:logger] ||= Rails.logger
    end

    def execute
      # Migrate repository from Legacy to Hashed Storage
      unless project.hashed_storage?(:repository)
        return unless HashedStorage::MigrateRepositoryService.new(project, options).execute
      end

      # Migrate attachments from Legacy to Hashed Storage
      unless project.hashed_storage?(:attachments)
        HashedStorage::MigrateAttachmentsService.new(project, options).execute
      end
    end
  end
end
