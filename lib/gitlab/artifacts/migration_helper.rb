# frozen_string_literal: true

module Gitlab
  module Artifacts
    class MigrationHelper
      def migrate_to_remote_storage(&block)
        artifacts = ::Ci::JobArtifact.with_files_stored_locally
        migrate(artifacts, ObjectStorage::Store::REMOTE, &block)
      end

      def migrate_to_local_storage(&block)
        artifacts = ::Ci::JobArtifact.with_files_stored_remotely
        migrate(artifacts, ObjectStorage::Store::LOCAL, &block)
      end

      private

      def batch_size
        ENV.fetch('MIGRATION_BATCH_SIZE', 10).to_i
      end

      def migrate(artifacts, store, &block)
        artifacts.find_each(batch_size: batch_size) do |artifact| # rubocop:disable CodeReuse/ActiveRecord
          artifact.file.migrate!(store)

          yield artifact if block
        rescue => e
          raise StandardError.new("Failed to transfer artifact of type #{artifact.file_type} and ID #{artifact.id} with error: #{e.message}")
        end
      end
    end
  end
end
