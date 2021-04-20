# frozen_string_literal: true

module Gitlab
  module Pages
    class MigrationHelper
      def initialize(logger = nil)
        @logger = logger
      end

      def migrate_to_remote_storage
        deployments = ::PagesDeployment.with_files_stored_locally
        migrate(deployments, ObjectStorage::Store::REMOTE)
      end

      def migrate_to_local_storage
        deployments = ::PagesDeployment.with_files_stored_remotely
        migrate(deployments, ObjectStorage::Store::LOCAL)
      end

      private

      def batch_size
        ENV.fetch('MIGRATION_BATCH_SIZE', 10).to_i
      end

      def migrate(deployments, store)
        deployments.find_each(batch_size: batch_size) do |deployment| # rubocop:disable CodeReuse/ActiveRecord
          deployment.file.migrate!(store)

          log_success(deployment, store)
        rescue => e
          log_error(e, deployment)
        end
      end

      def log_success(deployment, store)
        logger.info("Transferred deployment ID #{deployment.id} of type #{deployment.file_type} with size #{deployment.size} to #{storage_label(store)} storage")
      end

      def log_error(err, deployment)
        logger.warn("Failed to transfer deployment of type #{deployment.file_type} and ID #{deployment.id} with error: #{err.message}")
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
