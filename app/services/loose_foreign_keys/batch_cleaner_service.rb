# frozen_string_literal: true

module LooseForeignKeys
  class BatchCleanerService
    def initialize(parent_table:, loose_foreign_key_definitions:, deleted_parent_records:, modification_tracker: LooseForeignKeys::ModificationTracker.new)
      @parent_table = parent_table
      @loose_foreign_key_definitions = loose_foreign_key_definitions
      @deleted_parent_records = deleted_parent_records
      @modification_tracker = modification_tracker
      @deleted_records_counter = Gitlab::Metrics.counter(
        :loose_foreign_key_processed_deleted_records,
        'The number of processed loose foreign key deleted records'
      )
    end

    def execute
      loose_foreign_key_definitions.each do |loose_foreign_key_definition|
        run_cleaner_service(loose_foreign_key_definition, with_skip_locked: true)
        break if modification_tracker.over_limit?

        run_cleaner_service(loose_foreign_key_definition, with_skip_locked: false)
        break if modification_tracker.over_limit?
      end

      return if modification_tracker.over_limit?

      # At this point, all associations are cleaned up, we can update the status of the parent records
      update_count = LooseForeignKeys::DeletedRecord.mark_records_processed(deleted_parent_records)

      deleted_records_counter.increment({ table: parent_table, db_config_name: LooseForeignKeys::DeletedRecord.connection.pool.db_config.name }, update_count)
    end

    private

    attr_reader :parent_table, :loose_foreign_key_definitions, :deleted_parent_records, :modification_tracker, :deleted_records_counter

    def record_result(cleaner, result)
      if cleaner.async_delete?
        modification_tracker.add_deletions(result[:table], result[:affected_rows])
      elsif cleaner.async_nullify?
        modification_tracker.add_updates(result[:table], result[:affected_rows])
      end
    end

    def run_cleaner_service(loose_foreign_key_definition, with_skip_locked:)
      base_models_for_gitlab_schema = Gitlab::Database.schemas_to_base_models.fetch(loose_foreign_key_definition.options[:gitlab_schema])
      base_models_for_gitlab_schema.each do |base_model|
        cleaner = CleanerService.new(
          loose_foreign_key_definition: loose_foreign_key_definition,
          connection: base_model.connection,
          deleted_parent_records: deleted_parent_records,
          with_skip_locked: with_skip_locked
        )

        loop do
          result = cleaner.execute
          record_result(cleaner, result)

          break if modification_tracker.over_limit? || result[:affected_rows] == 0
        end
      end
    end
  end
end
