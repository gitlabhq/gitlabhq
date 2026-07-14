# frozen_string_literal: true

module Gitlab
  module Metrics
    # Short-lived facade observability for `Gitlab::LooseForeignKeys::DeletedRecordStore`.
    # It will be removed in Phase 5 (#597949).
    #
    # While `use_loose_foreign_keys_deleted_record_store` is being rolled out, these per-model counters
    # let us verify the facade is working correctly and watch traffic shift from the cell-local table to the
    # sharding-key tables. The long-term metrics live in `LooseForeignKeys::BatchCleanerService` and are not
    # affected by this module.
    module LooseForeignKeysDeletedRecordStore
      class << self
        def record_loaded(model_table_name, source_table, count)
          loaded_counter.increment({ model: model_table_name, table: source_table }, count)
        end

        def record_processed(per_model_counts)
          record(processed_counter, per_model_counts)
        end

        def record_rescheduled(per_model_counts)
          record(rescheduled_counter, per_model_counts)
        end

        def record_incremented(per_model_counts)
          record(incremented_counter, per_model_counts)
        end

        private

        def record(counter, per_model_counts)
          per_model_counts.each do |model_table_name, count|
            counter.increment({ model: model_table_name }, count)
          end
        end

        def loaded_counter
          Gitlab::Metrics.counter(
            :loose_foreign_key_deleted_record_store_loaded_records,
            'The number of loose foreign key deleted records loaded per model by the DeletedRecordStore'
          )
        end

        def processed_counter
          Gitlab::Metrics.counter(
            :loose_foreign_key_deleted_record_store_processed_records,
            'The number of loose foreign key deleted records processed per model by the DeletedRecordStore'
          )
        end

        def rescheduled_counter
          Gitlab::Metrics.counter(
            :loose_foreign_key_deleted_record_store_rescheduled_records,
            'The number of loose foreign key deleted records rescheduled per model by the DeletedRecordStore'
          )
        end

        def incremented_counter
          Gitlab::Metrics.counter(
            :loose_foreign_key_deleted_record_store_incremented_records,
            'The number of loose foreign key deleted records with incremented cleanup_attempts per model'
          )
        end
      end
    end
  end
end
