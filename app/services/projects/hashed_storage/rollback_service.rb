# frozen_string_literal: true

module Projects
  module HashedStorage
    class RollbackService < BaseService
      attr_reader :logger, :old_disk_path

      def initialize(project, old_disk_path, logger: nil)
        @project = project
        @old_disk_path = old_disk_path
        @logger = logger || Rails.logger # rubocop:disable Gitlab/RailsLogger
      end

      def execute
        # Rollback attachments from Hashed Storage to Legacy
        if project.hashed_storage?(:attachments)
          return false unless rollback_attachments
        end

        # Rollback repository from Hashed Storage to Legacy
        if project.hashed_storage?(:repository)
          rollback_repository
        end
      end

      private

      def rollback_attachments
        HashedStorage::RollbackAttachmentsService.new(project, logger: logger).execute
      end

      def rollback_repository
        HashedStorage::RollbackRepositoryService.new(project, old_disk_path, logger: logger).execute
      end
    end
  end
end
