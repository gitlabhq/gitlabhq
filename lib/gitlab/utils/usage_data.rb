# frozen_string_literal: true

# Usage data utilities
#
#   * distinct_count(relation, column = nil, batch: true, start: nil, finish: nil)
#     Does a distinct batch count, smartly reduces batch_size and handles errors
#
#     Examples:
#     issues_using_zoom_quick_actions: distinct_count(ZoomMeeting, :issue_id),
#
#   * count(relation, column = nil, batch: true, start: nil, finish: nil)
#     Does a non-distinct batch count, smartly reduces batch_size and handles errors
#
#     Examples:
#     active_user_count: count(User.active)
#
#   * alt_usage_data method
#     handles StandardError and fallbacks by default into -1 this way not all measures fail if we encounter one exception
#     there might be cases where we need to set a specific fallback in order to be aligned wih what version app is expecting as a type
#
#     Examples:
#     alt_usage_data { Gitlab::VERSION }
#     alt_usage_data { Gitlab::CurrentSettings.uuid }
#     alt_usage_data(fallback: nil) { Gitlab.config.registry.enabled }
#
#   * redis_usage_data method
#     handles ::Redis::CommandError, Gitlab::UsageDataCounters::BaseCounter::UnknownEvent,
#     Gitlab::UsageDataCounters::HLLRedisCounter::EventError
#     returns -1 when a block is sent or hash with all values -1 when a counter is sent
#     different behaviour due to 2 different implementations of redis counter
#
#     Examples:
#     redis_usage_data(Gitlab::UsageDataCounters::WikiPageCounter)
#     redis_usage_data { ::Gitlab::UsageCounters::PodLogs.usage_totals[:total] }

module Gitlab
  module Utils
    module UsageData
      include Gitlab::Utils::StrongMemoize
      extend self

      FALLBACK = -1
      HISTOGRAM_FALLBACK = { '-1' => -1 }.freeze
      DISTRIBUTED_HLL_FALLBACK = -2
      ALL_TIME_TIME_FRAME_NAME = "all"
      SEVEN_DAYS_TIME_FRAME_NAME = "7d"
      TWENTY_EIGHT_DAYS_TIME_FRAME_NAME = "28d"
      MAX_BUCKET_SIZE = 100

      def count(relation, column = nil, batch: true, batch_size: nil, start: nil, finish: nil)
        if batch
          Gitlab::Database::BatchCount.batch_count(relation, column, batch_size: batch_size, start: start, finish: finish)
        else
          relation.count
        end
      rescue ActiveRecord::StatementInvalid
        FALLBACK
      end

      def distinct_count(relation, column = nil, batch: true, batch_size: nil, start: nil, finish: nil)
        if batch
          Gitlab::Database::BatchCount.batch_distinct_count(relation, column, batch_size: batch_size, start: start, finish: finish)
        else
          relation.distinct_count_by(column)
        end
      rescue ActiveRecord::StatementInvalid
        FALLBACK
      end

      def estimate_batch_distinct_count(relation, column = nil, batch_size: nil, start: nil, finish: nil)
        buckets = Gitlab::Database::PostgresHll::BatchDistinctCounter
          .new(relation, column)
          .execute(batch_size: batch_size, start: start, finish: finish)

        yield buckets if block_given?

        buckets.estimated_distinct_count
      rescue ActiveRecord::StatementInvalid
        FALLBACK
      # catch all rescue should be removed as a part of feature flag rollout issue
      # https://gitlab.com/gitlab-org/gitlab/-/issues/285485
      rescue StandardError => error
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(error)
        DISTRIBUTED_HLL_FALLBACK
      end

      def sum(relation, column, batch_size: nil, start: nil, finish: nil)
        Gitlab::Database::BatchCount.batch_sum(relation, column, batch_size: batch_size, start: start, finish: finish)
      rescue ActiveRecord::StatementInvalid
        FALLBACK
      end

      # We don't support batching with histograms.
      # Please avoid using this method on large tables.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/323949.
      #
      # rubocop: disable CodeReuse/ActiveRecord
      def histogram(relation, column, buckets:, bucket_size: buckets.size)
        # Using lambda to avoid exposing histogram specific methods
        parameters_valid = lambda do
          error_message =
            if buckets.first == buckets.last
              'Lower bucket bound cannot equal to upper bucket bound'
            elsif bucket_size == 0
              'Bucket size cannot be zero'
            elsif bucket_size > MAX_BUCKET_SIZE
              "Bucket size #{bucket_size} exceeds the limit of #{MAX_BUCKET_SIZE}"
            end

          return true unless error_message

          exception = ArgumentError.new(error_message)
          exception.set_backtrace(caller)
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(exception)

          false
        end

        return HISTOGRAM_FALLBACK unless parameters_valid.call

        count_grouped = relation.group(column).select(Arel.star.count.as('count_grouped'))
        cte = Gitlab::SQL::CTE.new(:count_cte, count_grouped)

        # For example, 9 segements gives 10 buckets
        bucket_segments = bucket_size - 1

        width_bucket = Arel::Nodes::NamedFunction
          .new('WIDTH_BUCKET', [cte.table[:count_grouped], buckets.first, buckets.last, bucket_segments])
          .as('buckets')

        query = cte
          .table
          .project(width_bucket, cte.table[:count])
          .group('buckets')
          .order('buckets')
          .with(cte.to_arel)

        # Return the histogram as a Hash because buckets are unique.
        relation
          .connection
          .exec_query(query.to_sql)
          .rows
          .to_h
          # Keys are converted to strings in Usage Ping JSON
          .stringify_keys
      rescue ActiveRecord::StatementInvalid => e
        Gitlab::AppJsonLogger.error(
          event: 'histogram',
          relation: relation.table_name,
          operation: 'histogram',
          operation_args: [column, buckets.first, buckets.last, bucket_segments],
          query: query.to_sql,
          message: e.message
        )

        HISTOGRAM_FALLBACK
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def add(*args)
        return -1 if args.any?(&:negative?)

        args.sum
      rescue StandardError
        FALLBACK
      end

      def alt_usage_data(value = nil, fallback: FALLBACK, &block)
        if block_given?
          yield
        else
          value
        end
      rescue
        fallback
      end

      def redis_usage_data(counter = nil, &block)
        if block_given?
          redis_usage_counter(&block)
        elsif counter.present?
          redis_usage_data_totals(counter)
        end
      end

      def with_prometheus_client(fallback: {}, verify: true)
        client = prometheus_client(verify: verify)
        return fallback unless client

        yield client
      rescue
        fallback
      end

      def measure_duration
        result = nil
        duration = Benchmark.realtime do
          result = yield
        end
        [result, duration]
      end

      def with_finished_at(key, &block)
        yield.merge(key => Time.current)
      end

      # @param event_name [String] the event name
      # @param values [Array|String] the values counted
      def track_usage_event(event_name, values)
        Gitlab::UsageDataCounters::HLLRedisCounter.track_event(event_name.to_s, values: values)
      end

      def maximum_id(model)
        key = :"#{model.name.downcase}_maximum_id"
        strong_memoize(key) do
          model.maximum(:id)
        end
      end

      def minimum_id(model)
        key = :"#{model.name.downcase}_minimum_id"
        strong_memoize(key) do
          model.minimum(:id)
        end
      end

      private

      def prometheus_client(verify:)
        server_address = prometheus_server_address

        return unless server_address

        # There really is not a way to discover whether a Prometheus connection is using TLS or not
        # Try TLS first because HTTPS will return fast if failed.
        %w[https http].find do |scheme|
          api_url = "#{scheme}://#{server_address}"
          client = Gitlab::PrometheusClient.new(api_url, allow_local_requests: true, verify: verify)
          break client if client.ready?
        rescue
          nil
        end
      end

      def prometheus_server_address
        if Gitlab::Prometheus::Internal.prometheus_enabled?
          # Stripping protocol from URI
          Gitlab::Prometheus::Internal.uri&.strip&.sub(%r{^https?://}, '')
        elsif Gitlab::Consul::Internal.api_url
          Gitlab::Consul::Internal.discover_prometheus_server_address
        end
      end

      def redis_usage_counter
        yield
      rescue ::Redis::CommandError, Gitlab::UsageDataCounters::BaseCounter::UnknownEvent, Gitlab::UsageDataCounters::HLLRedisCounter::EventError
        FALLBACK
      end

      def redis_usage_data_totals(counter)
        counter.totals
      rescue ::Redis::CommandError, Gitlab::UsageDataCounters::BaseCounter::UnknownEvent
        counter.fallback_totals
      end
    end
  end
end
