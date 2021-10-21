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

        model = find_parent_model!(table)

        LooseForeignKeys::BatchCleanerService
          .new(parent_klass: model,
               deleted_parent_records: records,
               modification_tracker: modification_tracker,
               models_by_table_name: models_by_table_name)
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

    def find_parent_model!(table)
      models_by_table_name.fetch(table)
    end

    def current_schema
      @current_schema = connection.current_schema
    end

    def tracked_tables
      @tracked_tables ||= models_by_table_name
        .select { |table_name, model| model.respond_to?(:loose_foreign_key_definitions) }
        .keys
    end

    def models_by_table_name
      @models_by_table_name ||= begin
        all_models
          .select(&:base_class?)
          .index_by(&:table_name)
      end
    end

    def all_models
      ApplicationRecord.descendants
    end
  end
end
