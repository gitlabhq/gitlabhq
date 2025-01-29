# frozen_string_literal: true

module Gitlab
  module Instrumentation
    class Zoekt
      ZOEKT_REQUEST_COUNT = :zoekt_request_count
      ZOEKT_CALL_DURATION = :zoekt_call_duration
      ZOEKT_GRAPHQL_DURATION = :zoekt_graphql_duration
      ZOEKT_CALL_DETAILS = :zoekt_call_details

      class << self
        def get_request_count
          ::Gitlab::SafeRequestStore[ZOEKT_REQUEST_COUNT] || 0
        end

        def increment_request_count
          ::Gitlab::SafeRequestStore[ZOEKT_REQUEST_COUNT] ||= 0
          ::Gitlab::SafeRequestStore[ZOEKT_REQUEST_COUNT] += 1
        end

        def detail_store
          ::Gitlab::SafeRequestStore[ZOEKT_CALL_DETAILS] ||= []
        end

        def zoekt_call_duration
          ::Gitlab::SafeRequestStore[ZOEKT_CALL_DURATION] || 0
        end

        def query_time
          query_time = zoekt_call_duration + (::Gitlab::SafeRequestStore[ZOEKT_GRAPHQL_DURATION] || 0)
          query_time.round(::Gitlab::InstrumentationHelper::DURATION_PRECISION)
        end

        def add_duration(duration)
          ::Gitlab::SafeRequestStore[ZOEKT_CALL_DURATION] ||= 0
          ::Gitlab::SafeRequestStore[ZOEKT_CALL_DURATION] += duration
        end

        def add_graphql_duration(duration)
          ::Gitlab::SafeRequestStore[ZOEKT_GRAPHQL_DURATION] ||= 0
          ::Gitlab::SafeRequestStore[ZOEKT_GRAPHQL_DURATION] += duration
        end

        def add_call_details(duration:, method:, path:, params: nil, body: nil)
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
end
