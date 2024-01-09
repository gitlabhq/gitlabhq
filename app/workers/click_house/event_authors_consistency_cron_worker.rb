# frozen_string_literal: true

module ClickHouse
  # rubocop: disable CodeReuse/ActiveRecord -- Building worker-specific ActiveRecord and ClickHouse queries
  class EventAuthorsConsistencyCronWorker
    include ApplicationWorker
    include ClickHouseWorker
    include Gitlab::ExclusiveLeaseHelpers
    include Gitlab::Utils::StrongMemoize

    idempotent!
    queue_namespace :cronjob
    data_consistency :delayed
    worker_has_external_dependencies! # the worker interacts with a ClickHouse database
    feature_category :value_stream_management

    MAX_TTL = 5.minutes.to_i
    MAX_RUNTIME = 150.seconds
    MAX_AUTHOR_DELETIONS = 2000
    CLICK_HOUSE_BATCH_SIZE = 100_000
    POSTGRESQL_BATCH_SIZE = 2500

    def perform
      return unless enabled?

      runtime_limiter = Analytics::CycleAnalytics::RuntimeLimiter.new(MAX_RUNTIME)

      in_lock(self.class.to_s, ttl: MAX_TTL, retries: 0) do
        author_records_to_delete = []
        last_processed_id = 0
        iterator.each_batch(column: :author_id, of: CLICK_HOUSE_BATCH_SIZE) do |scope|
          query = scope.select(Arel.sql('DISTINCT author_id')).to_sql
          ids_from_click_house = connection.select(query).pluck('author_id').sort

          ids_from_click_house.each_slice(POSTGRESQL_BATCH_SIZE) do |ids|
            author_records_to_delete.concat(missing_user_ids(ids))
            last_processed_id = ids.last

            to_be_deleted_size = author_records_to_delete.size
            if to_be_deleted_size >= MAX_AUTHOR_DELETIONS
              metadata.merge!(status: :deletion_limit_reached, deletions: to_be_deleted_size)
              break
            end

            if runtime_limiter.over_time?
              metadata.merge!(status: :over_time, deletions: to_be_deleted_size)
              break
            end
          end

          break if limit_was_reached?
        end

        delete_records_from_click_house(author_records_to_delete)

        last_processed_id = 0 if table_fully_processed?
        ClickHouse::SyncCursor.update_cursor_for(:event_authors_consistency_check, last_processed_id)

        log_extra_metadata_on_done(:result, metadata)
      end
    end

    private

    def metadata
      @metadata ||= { status: :processed, deletions: 0 }
    end

    def limit_was_reached?
      metadata[:status] == :deletion_limit_reached || metadata[:status] == :over_time
    end

    def table_fully_processed?
      metadata[:status] == :processed
    end

    def enabled?
      ClickHouse::Client.database_configured?(:main) && Feature.enabled?(:event_sync_worker_for_click_house)
    end

    def previous_author_id
      value = ClickHouse::SyncCursor.cursor_for(:event_authors_consistency_check)
      value == 0 ? nil : value
    end
    strong_memoize_attr :previous_author_id

    def iterator
      builder = ClickHouse::QueryBuilder.new('event_authors')
      ClickHouse::Iterator.new(query_builder: builder, connection: connection, min_value: previous_author_id)
    end

    def connection
      @connection ||= ClickHouse::Connection.new(:main)
    end

    def missing_user_ids(ids)
      value_list = Arel::Nodes::ValuesList.new(ids.map { |id| [id] })
      User
        .from("(#{value_list.to_sql}) AS user_ids(id)")
        .where('NOT EXISTS (SELECT 1 FROM users WHERE id = user_ids.id)')
        .pluck(:id)
    end

    def delete_records_from_click_house(ids)
      query = ClickHouse::Client::Query.new(
        raw_query: "DELETE FROM events WHERE author_id IN ({author_ids:Array(UInt64)})",
        placeholders: { author_ids: ids.to_json }
      )

      connection.execute(query)

      query = ClickHouse::Client::Query.new(
        raw_query: "DELETE FROM event_authors WHERE author_id IN ({author_ids:Array(UInt64)})",
        placeholders: { author_ids: ids.to_json }
      )

      connection.execute(query)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
