# frozen_string_literal: true

module ActiveContext
  module Concerns
    module MigrationWorker
      extend ActiveSupport::Concern

      RE_ENQUEUE_DELAY = 30.seconds
      LOCK_TIMEOUT = 30.minutes
      LOCK_SLEEP_SEC = 2
      LOCK_RETRIES = 10

      def perform
        return false unless preflight_checks

        if failed_migrations?
          log 'Found failed migrations. All future migrations will be halted. Exiting'
          return
        end

        preprocess_migration_records!

        in_lock(self.class.name.underscore, ttl: LOCK_TIMEOUT, retries: LOCK_RETRIES, sleep_sec: LOCK_SLEEP_SEC) do
          execute_current_migration
        end
      end

      private

      def preflight_checks
        unless ActiveContext::Config.indexing_enabled?
          log 'indexing disabled. Execution is skipped.'
          return false
        end

        unless adapter
          log 'adapter not configured. Execution is skipped.'
          return false
        end

        true
      end

      def failed_migrations?
        migrations.failed.any?
      end

      def preprocess_migration_records!
        migration_files = migration_dictionary_instance.migrations(versions_only: true)
        migration_records = migrations.pluck(:version)

        create_missing_migration_records!(migration_files - migration_records)
        delete_orphaned_migration_records!(migration_records - migration_files)
      end

      def execute_current_migration
        migration_record = migrations.current

        unless migration_record
          log 'No pending migrations to process'
          return true
        end

        process_migration!(migration_record)

        true
      end

      def process_migration!(migration_record)
        migration_class = find_migration_class(migration_record.version)

        migration_instance = migration_class.new

        log "Starting migration #{migration_record.version}"

        migration_record.mark_as_started!
        migration_instance.migrate!

        if migration_instance.all_operations_completed?
          log "Marking migration #{migration_record.version} as completed"

          migration_record.mark_as_completed!
        else
          log "Migration #{migration_record.version} partially completed, re-enqueueing worker"

          re_enqueue_worker
        end
      rescue StandardError => e
        migration_record.decrease_retries!(e)

        log "Migration #{migration_record.version} failed: #{e.message}. Retries left: #{migration_record.retries_left}"
      end

      def create_missing_migration_records!(versions)
        return unless versions.any?

        connection = adapter.connection

        versions.each do |version|
          Ai::ActiveContext::Migration.create!(connection: connection, version: version)
        end

        log "Created missing migration records for #{versions.join(', ')}"
      end

      def delete_orphaned_migration_records!(versions)
        return unless versions.any?

        migrations.where(version: versions).delete_all

        log "Deleted orphaned migration records for #{versions.join(', ')}"
      end

      def re_enqueue_worker
        self.class.perform_in(RE_ENQUEUE_DELAY)
      end

      def migrations
        adapter.connection.migrations
      end

      def find_migration_class(version)
        migration_dictionary_instance.find_by_version(version)
      end

      def migration_dictionary_instance
        @migration_dictionary_instance ||= ::ActiveContext::Migration::Dictionary.instance
      end

      def log(message)
        ActiveContext::Config.logger.info(structured_payload(message: "#{self.class}: #{message}"))
      end

      def adapter
        @adapter ||= ActiveContext.adapter
      end
    end
  end
end
