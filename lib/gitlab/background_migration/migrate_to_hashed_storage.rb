# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Background migration to move any legacy project to Hashed Storage
    class MigrateToHashedStorage
      def perform
        batch_size = helper.batch_size
        legacy_projects_count = Project.with_unmigrated_storage.count

        if storage_migrator.rollback_pending?
          logger.warn(
            migrator: 'MigrateToHashedStorage',
            message: 'Aborting an storage rollback operation currently in progress'
          )

          storage_migrator.abort_rollback!
        end

        if legacy_projects_count == 0
          logger.info(
            migrator: 'MigrateToHashedStorage',
            message: 'There are no projects requiring migration to Hashed Storage'
          )

          return
        end

        logger.info(
          migrator: 'MigrateToHashedStorage',
          message: "Enqueuing migration of #{legacy_projects_count} projects in batches of #{batch_size}"
        )

        helper.project_id_batches_migration do |start, finish|
          storage_migrator.bulk_schedule_migration(start: start, finish: finish)

          logger.info(
            migrator: 'MigrateToHashedStorage',
            message: "Enqueuing migration of projects in batches of #{batch_size} from ID=#{start} to ID=#{finish}",
            batch_from: start,
            batch_to: finish
          )
        end
      end

      private

      def helper
        Gitlab::HashedStorage::RakeHelper
      end

      def storage_migrator
        @storage_migrator ||= Gitlab::HashedStorage::Migrator.new
      end

      def logger
        @logger ||= ::Gitlab::BackgroundMigration::Logger.build
      end
    end
  end
end
