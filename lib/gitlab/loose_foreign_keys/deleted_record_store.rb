# frozen_string_literal: true

module Gitlab
  module LooseForeignKeys
    # Facade that fans loose foreign key cleanup operations across the cell-local DeletedRecord table and the four
    # sharding-key-specific tables.
    #
    # Reads (load_batch_for_table) fan out to every model, merge results by the global consume order
    # [partition_number, consume_after, id] and truncate to the requested batch size.
    # Writes (mark_records_processed, reschedule, increment_attempts) are routed back to the originating model based on
    # the record's class.
    #
    # Per-model rollout metrics are emitted by `Gitlab::Metrics::LooseForeignKeysDeletedRecordStore`. They are
    # short-lived facade observability and will be removed in Phase 5 (#597949) once the facade becomes the only path.
    #
    # Callers must wrap invocations in `Gitlab::Database::SharedModel.using_connection(connection)` so that all five
    # models query the same physical database (e.g. `main`, `ci`, or `sec`) as the caller. The five sibling tables are
    # colocated on the same connection; the wrapping selects which database the queries hit, not the sharding key.
    #
    # The facade does not wrap internally because each worker deliberately picks its `connection:` per database.
    class DeletedRecordStore
      MODELS = [
        ::LooseForeignKeys::DeletedRecord,
        ::LooseForeignKeys::OrganizationDeletedRecord,
        ::LooseForeignKeys::NamespaceDeletedRecord,
        ::LooseForeignKeys::ProjectDeletedRecord,
        ::LooseForeignKeys::UserDeletedRecord
      ].freeze

      class << self
        # Fans the read to every model with the full `batch_size` to preserve the global
        # [partition_number, consume_after, id] consume order across all sibling tables, then truncates to
        # `batch_size`. Worst case: `MODELS.size * batch_size` records loaded in Ruby per call (~ 5 * 500 = 2,500
        # with the default `ProcessDeletedRecordsService::BATCH_SIZE`). Until Phase 3 routes inserts via the trigger
        # function, four of the five siblings return 0 rows, so steady-state load is `batch_size`.
        def load_batch_for_table(table, batch_size)
          records = MODELS.flat_map do |model|
            model_records = model.load_batch_for_table(table, batch_size)

            metrics.record_loaded(model.table_name, table, model_records.size)

            model_records
          end

          records
            .sort_by { |record| [record.partition_number, record.consume_after, record.id] }
            .first(batch_size)
        end

        def mark_records_processed(records)
          per_model_counts = count_per_model(records) do |model, model_records|
            model.mark_records_processed(model_records)
          end

          metrics.record_processed(per_model_counts)
          total(per_model_counts)
        end

        def reschedule(records, consume_after)
          per_model_counts = count_per_model(records) do |model, model_records|
            model.reschedule(model_records, consume_after)
          end

          metrics.record_rescheduled(per_model_counts)
          total(per_model_counts)
        end

        def increment_attempts(records)
          per_model_counts = count_per_model(records) do |model, model_records|
            model.increment_attempts(model_records)
          end

          metrics.record_incremented(per_model_counts)
          total(per_model_counts)
        end

        # Used by `LooseForeignKeys::BatchCleanerService#db_config_name` to resolve the DB pool name via the injected
        # `record_store` instead of hardcoding `LooseForeignKeys::DeletedRecord`. All five tables share the same
        # connection, so returning the cell-local `DeletedRecord.connection` works for all tables.
        def connection
          ::LooseForeignKeys::DeletedRecord.connection
        end

        private

        # Groups records by their originating model, runs the given write operation per model, and returns a hash
        # of { model_table_name => affected_count }.
        def count_per_model(records)
          records.group_by(&:class).each_with_object({}) do |(model, model_records), counts|
            counts[model.table_name] = yield(model, model_records)
          end
        end

        def total(per_model_counts)
          per_model_counts.values.sum
        end

        def metrics
          Gitlab::Metrics::LooseForeignKeysDeletedRecordStore
        end
      end
    end
  end
end
