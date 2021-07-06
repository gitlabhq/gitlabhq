# frozen_string_literal: true

module Gitlab
  module LocalAndRemoteStorageMigration
    class BaseMigrater
      def initialize(logger = nil)
        @logger = logger
      end

      def migrate_to_remote_storage
        logger.info('Starting transfer to object storage')

        migrate(items_with_files_stored_locally, ObjectStorage::Store::REMOTE)
      end

      def migrate_to_local_storage
        logger.info('Starting transfer to local storage')

        migrate(items_with_files_stored_remotely, ObjectStorage::Store::LOCAL)
      end

      private

      attr_reader :logger

      def batch_size
        ENV.fetch('MIGRATION_BATCH_SIZE', 10).to_i
      end

      def migrate(items, store)
        items.find_each(batch_size: batch_size) do |item| # rubocop:disable CodeReuse/ActiveRecord
          item.file.migrate!(store)

          log_success(item, store)
        rescue StandardError => e
          log_error(e, item)
        end
      end

      def log_success(item, store)
        logger.info("Transferred #{item.class.name} ID #{item.id} with size #{item.size} to #{storage_label(store)} storage")
      end

      def log_error(err, item)
        logger.warn("Failed to transfer #{item.class.name} ID #{item.id} with error: #{err.message}")
      end

      def storage_label(store)
        if store == ObjectStorage::Store::LOCAL
          'local'
        else
          'object'
        end
      end
    end
  end
end
