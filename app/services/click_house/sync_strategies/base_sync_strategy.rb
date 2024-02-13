# frozen_string_literal: true

module ClickHouse
  module SyncStrategies
    class BaseSyncStrategy
      include Gitlab::ExclusiveLeaseHelpers
      include Gitlab::Utils::StrongMemoize

      # the job is scheduled every 3 minutes and we will allow maximum 2.5 minutes runtime
      MAX_TTL = 2.5.minutes.to_i
      MAX_RUNTIME = 120.seconds
      BATCH_SIZE = 500
      INSERT_BATCH_SIZE = 5000

      def execute
        return { status: :disabled } unless enabled?

        metadata = { status: :processed }

        begin
          # Prevent parallel jobs
          in_lock(self.class.to_s, ttl: MAX_TTL, retries: 0) do
            loop { break unless next_batch }

            metadata.merge!(records_inserted: context.total_record_count,
              reached_end_of_table: context.no_more_records?)

            if context.last_processed_id
              ClickHouse::SyncCursor.update_cursor_for(model_class.table_name,
                context.last_processed_id)
            end
          end
        rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
          # Skip retrying, just let the next worker to start after a few minutes
          metadata = { status: :skipped }
        end

        metadata
      end

      private

      def enabled?
        Gitlab::ClickHouse.configured?
      end

      def context
        @context ||= ClickHouse::RecordSyncContext.new(
          last_record_id: ClickHouse::SyncCursor.cursor_for(model_class.table_name),
          max_records_per_batch: INSERT_BATCH_SIZE,
          runtime_limiter: Gitlab::Metrics::RuntimeLimiter.new(MAX_RUNTIME)
        )
      end

      def last_id_in_postgresql
        model_class.maximum(:id)
      end

      strong_memoize_attr :last_id_in_postgresql

      def next_batch
        context.new_batch!

        CsvBuilder::Gzip.new(process_batch(context), csv_mapping).render do |tempfile, rows_written|
          unless rows_written == 0
            ClickHouse::Client.insert_csv(insert_query, File.open(tempfile.path),
              :main)
          end
        end

        !(context.over_time? || context.no_more_records?)
      end

      def process_batch(context)
        Enumerator.new do |yielder|
          has_more_data = false
          batching_scope.each_batch(of: BATCH_SIZE) do |relation|
            records = relation.select(projections).to_a
            has_more_data = records.size == BATCH_SIZE
            records.each do |row|
              yielder << transform_row(row)
              context.last_processed_id = row.id

              break if context.record_limit_reached?
            end

            break if context.over_time? || context.record_limit_reached? || !has_more_data
          end

          context.no_more_records! unless has_more_data
        end
      end

      def transform_row(row)
        row
      end

      # rubocop: disable CodeReuse/ActiveRecord -- because model here is dynamic and is passed by child class
      def batching_scope
        return model_class.none unless last_id_in_postgresql

        table = model_class.arel_table

        model_class
          .where(table[:id].gt(context.last_record_id))
          .where(table[:id].lteq(last_id_in_postgresql))
      end

      # rubocop: enable CodeReuse/ActiveRecord

      def projections
        raise NotImplementedError, "Subclasses must implement `projections`"
      end

      def csv_mapping
        raise NotImplementedError, "Subclasses must implement `csv_mapping`"
      end

      def insert_query
        raise NotImplementedError, "Subclasses must implement `insert_query`"
      end
    end
  end
end
