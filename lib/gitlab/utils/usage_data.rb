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
#     handles ::Redis::CommandError, Gitlab::UsageDataCounters::BaseCounter::UnknownEvent
#     returns -1 when a block is sent or hash with all values -1 when a counter is sent
#     different behaviour due to 2 different implementations of redis counter
#
#     Examples:
#     redis_usage_data(Gitlab::UsageDataCounters::WikiPageCounter)
#     redis_usage_data { ::Gitlab::UsageCounters::PodLogs.usage_totals[:total] }

module Gitlab
  module Utils
    module UsageData
      extend self

      FALLBACK = -1
      DISTRIBUTED_HLL_FALLBACK = -2
      ALL_TIME_PERIOD_HUMAN_NAME = "all_time"
      WEEKLY_PERIOD_HUMAN_NAME = "weekly"
      MONTHLY_PERIOD_HUMAN_NAME = "monthly"

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

      def save_aggregated_metrics(metric_name:, time_period:, recorded_at_timestamp:, data:)
        unless data.is_a? ::Gitlab::Database::PostgresHll::Buckets
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(StandardError.new("Unsupported data type: #{data.class}"))
          return
        end

        # the longest recorded usage ping generation time for gitlab.com
        # was below 40 hours, there is added error margin of 20 h
        usage_ping_generation_period = 80.hours

        # add timestamp at the end of the key to avoid stale keys if
        # usage ping job is retried
        redis_key = "#{metric_name}_#{time_period_to_human_name(time_period)}-#{recorded_at_timestamp}"

        Gitlab::Redis::SharedState.with do |redis|
          redis.set(redis_key, data.to_json, ex: usage_ping_generation_period)
        end
      rescue ::Redis::CommandError => e
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
      end

      def sum(relation, column, batch_size: nil, start: nil, finish: nil)
        Gitlab::Database::BatchCount.batch_sum(relation, column, batch_size: batch_size, start: start, finish: finish)
      rescue ActiveRecord::StatementInvalid
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

      def with_prometheus_client(fallback: nil, verify: true)
        client = prometheus_client(verify: verify)
        return fallback unless client

        yield client
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
        return unless Feature.enabled?(:"usage_data_#{event_name}", default_enabled: true)

        Gitlab::UsageDataCounters::HLLRedisCounter.track_event(event_name.to_s, values: values)
      end

      def time_period_to_human_name(time_period)
        return ALL_TIME_PERIOD_HUMAN_NAME if time_period.blank?

        date_range = time_period.values[0]
        start_date = date_range.first.to_date
        end_date = date_range.last.to_date

        if (end_date - start_date).to_i > 7
          MONTHLY_PERIOD_HUMAN_NAME
        else
          WEEKLY_PERIOD_HUMAN_NAME
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
      rescue ::Redis::CommandError, Gitlab::UsageDataCounters::BaseCounter::UnknownEvent
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
