# frozen_string_literal: true

require 'elasticsearch-transport'

module Gitlab
  module Instrumentation
    module ElasticsearchTransportInterceptor
      def perform_request(method, path, params = {}, body = nil, headers = nil)
        start = Time.now
        headers = (headers || {})
          .reverse_merge({ 'X-Opaque-Id': Labkit::Correlation::CorrelationId.current_or_new_id })
        response = super
      ensure
        if ::Gitlab::SafeRequestStore.active?
          duration = (Time.now - start)

          ::Gitlab::Instrumentation::ElasticsearchTransport.increment_request_count

          if response&.body && response.body.is_a?(Hash) && response.body['timed_out']
            ::Gitlab::Instrumentation::ElasticsearchTransport.increment_timed_out_count
          end

          ::Gitlab::Instrumentation::ElasticsearchTransport.add_duration(duration)
          ::Gitlab::Instrumentation::ElasticsearchTransport.add_call_details(duration, method, path, params, body)
        end
      end
    end

    class ElasticsearchTransport
      ELASTICSEARCH_REQUEST_COUNT = :elasticsearch_request_count
      ELASTICSEARCH_CALL_DURATION = :elasticsearch_call_duration
      ELASTICSEARCH_CALL_DETAILS = :elasticsearch_call_details
      ELASTICSEARCH_TIMED_OUT_COUNT = :elasticsearch_timed_out_count

      def self.get_request_count
        ::Gitlab::SafeRequestStore[ELASTICSEARCH_REQUEST_COUNT] || 0
      end

      def self.increment_request_count
        ::Gitlab::SafeRequestStore[ELASTICSEARCH_REQUEST_COUNT] ||= 0
        ::Gitlab::SafeRequestStore[ELASTICSEARCH_REQUEST_COUNT] += 1
      end

      def self.detail_store
        ::Gitlab::SafeRequestStore[ELASTICSEARCH_CALL_DETAILS] ||= []
      end

      def self.query_time
        query_time = ::Gitlab::SafeRequestStore[ELASTICSEARCH_CALL_DURATION] || 0
        query_time.round(::Gitlab::InstrumentationHelper::DURATION_PRECISION)
      end

      def self.add_duration(duration)
        ::Gitlab::SafeRequestStore[ELASTICSEARCH_CALL_DURATION] ||= 0
        ::Gitlab::SafeRequestStore[ELASTICSEARCH_CALL_DURATION] += duration
      end

      def self.increment_timed_out_count
        ::Gitlab::SafeRequestStore[ELASTICSEARCH_TIMED_OUT_COUNT] ||= 0
        ::Gitlab::SafeRequestStore[ELASTICSEARCH_TIMED_OUT_COUNT] += 1
      end

      def self.get_timed_out_count
        ::Gitlab::SafeRequestStore[ELASTICSEARCH_TIMED_OUT_COUNT] || 0
      end

      def self.add_call_details(duration, method, path, params, body)
        return unless Gitlab::PerformanceBar.enabled_for_request?

        detail_store << {
          method: method,
          path: path,
          params: params,
          body: body,
          duration: duration,
          backtrace: ::Gitlab::BacktraceCleaner.clean_backtrace(caller)
        }
      end
    end
  end
end

class ::Elasticsearch::Transport::Client
  prepend ::Gitlab::Instrumentation::ElasticsearchTransportInterceptor
end
