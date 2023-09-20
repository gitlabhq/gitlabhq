# frozen_string_literal: true

module LooseForeignKeys
  class ProcessDeletedRecordsService
    BATCH_SIZE = 1000

    def initialize(connection:, modification_tracker: LooseForeignKeys::ModificationTracker.new)
      @connection = connection
      @modification_tracker = modification_tracker
    end

    def execute
      raised_error = false
      tracked_tables.cycle do |table|
        records = load_batch_for_table(table)

        if records.empty?
          tracked_tables.delete(table)
          next
        end

        break if modification_tracker.over_limit?

        loose_foreign_key_definitions = Gitlab::Database::LooseForeignKeys.definitions_by_table[table]

        next if loose_foreign_key_definitions.empty?

        LooseForeignKeys::BatchCleanerService
          .new(
            parent_table: table,
            loose_foreign_key_definitions: loose_foreign_key_definitions,
            deleted_parent_records: records,
            modification_tracker: modification_tracker)
          .execute

        break if modification_tracker.over_limit?
      end

      ::Gitlab::Metrics::LooseForeignKeysSlis.record_apdex(
        success: !modification_tracker.over_limit?,
        db_config_name: db_config_name
      )

      modification_tracker.stats
    rescue StandardError
      raised_error = true
      raise
    ensure
      ::Gitlab::Metrics::LooseForeignKeysSlis.record_error_rate(
        error: raised_error,
        db_config_name: db_config_name
      )
    end

    private

    attr_reader :connection, :modification_tracker

    def db_config_name
      ::Gitlab::Database.db_config_name(connection)
    end

    def load_batch_for_table(table)
      fully_qualified_table_name = "#{current_schema}.#{table}"
      LooseForeignKeys::DeletedRecord.load_batch_for_table(fully_qualified_table_name, BATCH_SIZE)
    end

    def current_schema
      @current_schema = connection.current_schema
    end

    def tracked_tables
      @tracked_tables ||= Gitlab::Database::LooseForeignKeys.definitions_by_table.keys.shuffle
    end
  end
end
