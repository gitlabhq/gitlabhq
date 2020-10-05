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

        Gitlab::UsageDataCounters::HLLRedisCounter.track_event(values, event_name.to_s)
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
          Gitlab::Prometheus::Internal.server_address
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
