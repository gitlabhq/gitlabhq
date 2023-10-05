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
        # Migrate attachments from Legacy to Hashed Storage
        unless project.hashed_storage?(:attachments)
          return false unless migrate_attachments_service.execute
        end

        true
      end

      private

      def migrate_attachments_service
        HashedStorage::MigrateAttachmentsService.new(project: project, old_disk_path: old_disk_path, logger: logger)
      end
    end
  end
end
