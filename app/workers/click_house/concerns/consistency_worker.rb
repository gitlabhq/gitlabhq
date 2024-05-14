# frozen_string_literal: true

module ClickHouse
  module Concerns
    # This module can be used for batching over a ClickHouse database table column
    # and do something with the yielded values. The module is responsible for
    # correctly restoring the state (cursor) in case the processing was
    # interrupted or restart the processing from the beginning of the table
    # when the table was fully processed.
    #
    # This class acts like a "template method" pattern where the implementor classes
    # need to define two methods:
    #
    # - init_context: Returns a memoized hash, initializing the context that controls the data processing.
    # - pluck_column: which column value to take from the ClickHouse DB when iterating
    # - process_collected_values: once a limit is reached or no more data, do something
    # - collect_values: filter, process and store the returned values from ClickHouse
    # with the collected values.
    module ConsistencyWorker
      extend ActiveSupport::Concern
      include Gitlab::Utils::StrongMemoize

      MAX_RUNTIME = 150.seconds
      MAX_TTL = 5.minutes.to_i
      CLICK_HOUSE_BATCH_SIZE = 100_000
      POSTGRESQL_BATCH_SIZE = 2500
      LIMIT_STATUSES = %i[limit_reached over_time].freeze

      included do
        include Gitlab::ExclusiveLeaseHelpers
      end

      def perform
        return unless enabled?

        init_context
        runtime_limiter
        click_house_each_batch do |values|
          collect_values(values)

          break if limit_was_reached?
        end

        process_collected_values

        context[:last_processed_id] = 0 if table_fully_processed?
        ClickHouse::SyncCursor.update_cursor_for(sync_cursor, context[:last_processed_id])
        log_extra_metadata_on_done(:result, metadata)
      end

      private

      attr_reader :context

      def click_house_each_batch
        in_lock(self.class.to_s, ttl: MAX_TTL, retries: 0) do
          iterator.each_batch(column: batch_column, of: CLICK_HOUSE_BATCH_SIZE) do |scope|
            query = scope.select(Arel.sql("DISTINCT #{pluck_column}")).to_sql
            ids_from_click_house = connection.select(query).pluck(pluck_column).sort # rubocop: disable CodeReuse/ActiveRecord -- limited query

            ids_from_click_house.each_slice(POSTGRESQL_BATCH_SIZE) do |values|
              yield values
            end
          end
        end
      end

      def enabled?
        Gitlab::ClickHouse.globally_enabled_for_analytics?
      end

      def runtime_limiter
        @runtime_limiter ||= Gitlab::Metrics::RuntimeLimiter.new(MAX_RUNTIME)
      end

      def iterator
        builder = ClickHouse::QueryBuilder.new(table.to_s)
        ClickHouse::Iterator.new(query_builder: builder, connection: connection, min_value: previous_id)
      end

      def sync_cursor
        "#{table}_consistency_check"
      end

      def previous_id
        value = ClickHouse::SyncCursor.cursor_for(sync_cursor)
        value == 0 ? nil : value
      end
      strong_memoize_attr :previous_id

      def metadata
        @metadata ||= { status: :processed, modifications: 0 }
      end

      def connection
        @connection ||= ClickHouse::Connection.new(:main)
      end

      def table_fully_processed?
        metadata[:status] == :processed
      end

      def limit_was_reached?
        LIMIT_STATUSES.include?(metadata[:status])
      end
    end
  end
end
