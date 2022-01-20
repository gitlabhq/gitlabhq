# frozen_string_literal: true

module LooseForeignKeys
  class ProcessDeletedRecordsService
    BATCH_SIZE = 1000

    def initialize(connection:)
      @connection = connection
    end

    def execute
      modification_tracker = ModificationTracker.new
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

      modification_tracker.stats
    end

    private

    attr_reader :connection

    def load_batch_for_table(table)
      fully_qualified_table_name = "#{current_schema}.#{table}"
      LooseForeignKeys::DeletedRecord.load_batch_for_table(fully_qualified_table_name, BATCH_SIZE)
    end

    def current_schema
      @current_schema = connection.current_schema
    end

    def tracked_tables
      @tracked_tables ||= Gitlab::Database::LooseForeignKeys.definitions_by_table.keys
    end
  end
end
