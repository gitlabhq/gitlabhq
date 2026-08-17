# frozen_string_literal: true

module Gitlab
  module Database
    module Reindexing
      # Number of indexes to reindex per invocation
      DEFAULT_INDEXES_PER_INVOCATION = 2

      SUPPORTED_TYPES = %w[btree gist].freeze

      # When dropping an index, we acquire a SHARE UPDATE EXCLUSIVE lock,
      # which only conflicts with DDL and vacuum. We therefore execute this with a rather
      # high lock timeout and a long pause in between retries. This is an alternative to
      # setting a high statement timeout, which would lead to a long running query with effects
      # on e.g. vacuum.
      REMOVE_INDEX_RETRY_CONFIG = [[1.minute, 9.minutes]] * 30

      def self.enabled?
        return false if Feature.enabled?(:disallow_database_ddl_feature_flags, type: :ops)

        Feature.enabled?(:database_reindexing, type: :ops)
      end

      def self.invoke(database = nil)
        Gitlab::Database::EachDatabase.each_connection do |connection, connection_name|
          next if database && database.to_s != connection_name.to_s

          Gitlab::Database::SharedModel.logger = Logger.new($stdout) if Gitlab::Utils.to_boolean(ENV['LOG_QUERIES_TO_CONSOLE'], default: false)

          if Feature.disabled?(:disallow_database_ddl_feature_flags, type: :ops) && Feature.enabled?(:database_async_index_creation, type: :ops)
            # Hack: Before we do actual reindexing work, create async indexes
            Gitlab::Database::AsyncIndexes.create_pending_indexes!
            Gitlab::Database::AsyncIndexes.drop_pending_indexes!
          end

          if Feature.disabled?(:disallow_database_ddl_feature_flags, type: :ops) && Feature.enabled?(:database_async_foreign_key_validation, type: :ops)
            Gitlab::Database::AsyncConstraints.validate_pending_entries!
          end

          automatic_reindexing
        end
      rescue StandardError => e
        Gitlab::AppLogger.error(e)
        raise
      end

      def self.stats(database = nil)
        Gitlab::Database::EachDatabase.each_connection do |connection, connection_name|
          next if database && database.to_s != connection_name.to_s

          log_pending_items(connection_name, "pending_indexes_to_create", Gitlab::Database::AsyncIndexes.pending_indexes_to_create)
          log_pending_items(connection_name, "pending_indexes_to_drop", Gitlab::Database::AsyncIndexes.pending_indexes_to_drop)
          log_pending_items(connection_name, "queued_indexes_to_reindex", queued_actions)
          log_pending_items(connection_name, "pending_async_check_constraints", Gitlab::Database::AsyncConstraints.pending_entries)
        end
      rescue StandardError => e
        Gitlab::AppLogger.error(e)
        raise
      end

      def self.log_pending_items(connection_name, label, items)
        Gitlab::AppLogger.info(message: 'Pending count', connection_name: connection_name, metric_label: label, count: items.count)
        items.each do |index|
          Gitlab::AppLogger.info(message: 'Pending item', connection_name: connection_name, metric_label: label, name: index.name)
        end
      end
      private_class_method :log_pending_items

      # Performs automatic reindexing for a limited number of indexes per call
      #  1. Consume from the explicit reindexing queue
      #  2. Apply bloat heuristic to find most bloated indexes and reindex those
      def self.automatic_reindexing(maximum_records: DEFAULT_INDEXES_PER_INVOCATION)
        # Cleanup leftover temporary indexes from previous, possibly aborted runs (if any)
        cleanup_leftovers!

        # Consume from the explicit reindexing queue first
        done_counter = perform_from_queue(maximum_records: maximum_records)

        return if done_counter >= maximum_records

        # Execute reindexing based on bloat heuristic
        perform_with_heuristic(maximum_records: maximum_records - done_counter)
      end

      # Reindex based on bloat heuristic for a limited number of indexes per call
      #
      # We use a bloat heuristic to estimate the index bloat and pick the
      # most bloated indexes for reindexing.
      def self.perform_with_heuristic(candidate_indexes = Gitlab::Database::PostgresIndex.reindexing_support, maximum_records: DEFAULT_INDEXES_PER_INVOCATION)
        IndexSelection.new(candidate_indexes).take(maximum_records).each do |index|
          Coordinator.new(index).perform
        end
      end

      def self.queued_actions
        QueuedAction.in_queue_order
      end
      private_class_method :queued_actions

      # Reindex indexes that have been explicitly enqueued (for a limited number of indexes per call)
      def self.perform_from_queue(maximum_records: DEFAULT_INDEXES_PER_INVOCATION)
        QueuedAction.in_queue_order.limit(maximum_records).each do |queued_entry|
          Coordinator.new(queued_entry.index).perform

          queued_entry.done!
        rescue StandardError => e
          queued_entry.failed!

          Gitlab::AppLogger.error("Failed to perform reindexing action on queued entry #{queued_entry}: #{e}")
        end.size
      end

      def self.cleanup_leftovers!
        PostgresIndex.reindexing_leftovers.each do |index|
          Coordinator.new(index).drop
        end
      end

      def self.minimum_index_size!(bytes)
        update_reindexing_setting!(:reindexing_minimum_index_size, bytes)
      end

      def self.minimum_relative_bloat_size!(threshold)
        update_reindexing_setting!(:reindexing_minimum_relative_bloat_size, threshold)
      end

      def self.update_reindexing_setting!(key, value)
        application_settings = Gitlab::CurrentSettings.current_application_settings
        current_settings = application_settings.database_reindexing || {}
        updated_settings = current_settings.merge(key => value)
        application_settings.update!(database_reindexing: updated_settings)
      end
      private_class_method :update_reindexing_setting!
    end
  end
end
