# frozen_string_literal: true

module ClickHouse
  class EventsSyncWorker
    include ApplicationWorker
    include ClickHouseWorker
    include Gitlab::ExclusiveLeaseHelpers
    include Gitlab::Utils::StrongMemoize

    idempotent!
    queue_namespace :cronjob
    data_consistency :delayed
    worker_has_external_dependencies! # the worker interacts with a ClickHouse database
    feature_category :value_stream_management

    # the job is scheduled every 3 minutes and we will allow maximum 2.5 minutes runtime
    MAX_TTL = 2.5.minutes.to_i
    MAX_RUNTIME = 120.seconds
    BATCH_SIZE = 500
    INSERT_BATCH_SIZE = 5000
    CSV_MAPPING = {
      id: :id,
      path: :path,
      author_id: :author_id,
      target_id: :target_id,
      target_type: :target_type,
      action: :raw_action,
      created_at: :casted_created_at,
      updated_at: :casted_updated_at
    }.freeze

    # transforms the traversal_ids to a String:
    # Example: group_id/subgroup_id/group_or_projectnamespace_id/
    PATH_COLUMN = <<~SQL
      (
        CASE
          WHEN project_id IS NOT NULL THEN (SELECT array_to_string(traversal_ids, '/') || '/' FROM namespaces WHERE id = (SELECT project_namespace_id FROM projects WHERE id = events.project_id LIMIT 1) LIMIT 1)
          WHEN group_id IS NOT NULL THEN (SELECT array_to_string(traversal_ids, '/') || '/' FROM namespaces WHERE id = events.group_id LIMIT 1)
          ELSE ''
        END
      ) AS path
    SQL

    EVENT_PROJECTIONS = [
      :id,
      PATH_COLUMN,
      :author_id,
      :target_id,
      :target_type,
      'action AS raw_action',
      'EXTRACT(epoch FROM created_at) AS casted_created_at',
      'EXTRACT(epoch FROM updated_at) AS casted_updated_at'
    ].freeze

    INSERT_EVENTS_QUERY = <<~SQL.squish
      INSERT INTO events (#{CSV_MAPPING.keys.join(', ')})
      SETTINGS async_insert=1, wait_for_async_insert=1 FORMAT CSV
    SQL

    def perform
      unless enabled?
        log_extra_metadata_on_done(:result, { status: :disabled })

        return
      end

      metadata = { status: :processed }

      begin
        # Prevent parallel jobs
        in_lock(self.class.to_s, ttl: MAX_TTL, retries: 0) do
          loop { break unless next_batch }

          metadata.merge!(records_inserted: context.total_record_count, reached_end_of_table: context.no_more_records?)

          ClickHouse::SyncCursor.update_cursor_for(:events, context.last_processed_id) if context.last_processed_id
        end
      rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
        # Skip retrying, just let the next worker to start after a few minutes
        metadata = { status: :skipped }
      end

      log_extra_metadata_on_done(:result, metadata)
    end

    private

    def context
      @context ||= ClickHouse::RecordSyncContext.new(
        last_record_id: ClickHouse::SyncCursor.cursor_for(:events),
        max_records_per_batch: INSERT_BATCH_SIZE,
        runtime_limiter: Analytics::CycleAnalytics::RuntimeLimiter.new(MAX_RUNTIME)
      )
    end

    def last_event_id_in_postgresql
      Event.maximum(:id)
    end
    strong_memoize_attr :last_event_id_in_postgresql

    def enabled?
      ClickHouse::Client.database_configured?(:main) && Feature.enabled?(:event_sync_worker_for_click_house)
    end

    def next_batch
      context.new_batch!

      CsvBuilder::Gzip.new(process_batch(context), CSV_MAPPING).render do |tempfile, rows_written|
        unless rows_written == 0
          ClickHouse::Client.insert_csv(INSERT_EVENTS_QUERY, File.open(tempfile.path),
            :main)
        end
      end

      !(context.over_time? || context.no_more_records?)
    end

    def process_batch(context)
      Enumerator.new do |yielder|
        has_more_data = false
        batching_scope.each_batch(of: BATCH_SIZE) do |relation|
          records = relation.select(*EVENT_PROJECTIONS).to_a
          has_more_data = records.size == BATCH_SIZE
          records.each do |row|
            yielder << row
            context.last_processed_id = row.id

            break if context.record_limit_reached?
          end

          break if context.over_time? || context.record_limit_reached? || !has_more_data
        end

        context.no_more_records! unless has_more_data
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def batching_scope
      return Event.none unless last_event_id_in_postgresql

      table = Event.arel_table

      Event
        .where(table[:id].gt(context.last_record_id))
        .where(table[:id].lteq(last_event_id_in_postgresql))
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
