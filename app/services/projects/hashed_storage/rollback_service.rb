# frozen_string_literal: true

module Projects
  module HashedStorage
    class RollbackService < BaseService
      attr_reader :logger, :old_disk_path

      def execute
        # Rollback attachments from Hashed Storage to Legacy
        if project.hashed_storage?(:attachments)
          return false unless rollback_attachments_service.execute
        end

        # Rollback repository from Hashed Storage to Legacy
        if project.hashed_storage?(:repository)
          rollback_repository_service.execute
        end
      end

      private

      def rollback_attachments_service
        HashedStorage::RollbackAttachmentsService.new(project: project, old_disk_path: old_disk_path, logger: logger)
      end

      def rollback_repository_service
        HashedStorage::RollbackRepositoryService.new(project: project, old_disk_path: old_disk_path, logger: logger)
      end
    end
  end
end
