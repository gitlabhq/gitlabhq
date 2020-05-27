# frozen_string_literal: true

require 'elasticsearch-transport'

module Gitlab
  module Instrumentation
    module ElasticsearchTransportInterceptor
      def perform_request(*args)
        start = Time.now
        super
      ensure
        if ::Gitlab::SafeRequestStore.active?
          duration = (Time.now - start)

          ::Gitlab::Instrumentation::ElasticsearchTransport.increment_request_count
          ::Gitlab::Instrumentation::ElasticsearchTransport.add_duration(duration)
          ::Gitlab::Instrumentation::ElasticsearchTransport.add_call_details(duration, args)
        end
      end
    end

    class ElasticsearchTransport
      ELASTICSEARCH_REQUEST_COUNT = :elasticsearch_request_count
      ELASTICSEARCH_CALL_DURATION = :elasticsearch_call_duration
      ELASTICSEARCH_CALL_DETAILS = :elasticsearch_call_details

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

      def self.add_call_details(duration, args)
        return unless Gitlab::PerformanceBar.enabled_for_request?

        detail_store << {
          method: args[0],
          path: args[1],
          params: args[2],
          body: args[3],
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
