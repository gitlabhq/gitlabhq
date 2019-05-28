# frozen_string_literal: true

module Projects
  module HashedStorage
    class MigrationService < BaseService
      attr_reader :logger, :old_disk_path

      def initialize(project, old_disk_path, logger: nil)
        @project = project
        @old_disk_path = old_disk_path
        @logger = logger || Gitlab::AppLogger
      end

      def execute
        # Migrate repository from Legacy to Hashed Storage
        unless project.hashed_storage?(:repository)
          return false unless migrate_repository
        end

        # Migrate attachments from Legacy to Hashed Storage
        unless project.hashed_storage?(:attachments)
          return false unless migrate_attachments
        end

        true
      end

      private

      def migrate_repository
        HashedStorage::MigrateRepositoryService.new(project, old_disk_path, logger: logger).execute
      end

      def migrate_attachments
        HashedStorage::MigrateAttachmentsService.new(project, old_disk_path, logger: logger).execute
      end
    end
  end
end
