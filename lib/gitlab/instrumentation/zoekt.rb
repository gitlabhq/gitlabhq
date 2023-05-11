# frozen_string_literal: true

module Gitlab
  module Instrumentation
    class Zoekt
      InstrumentationStorage = ::Gitlab::Instrumentation::Storage

      ZOEKT_REQUEST_COUNT = :zoekt_request_count
      ZOEKT_CALL_DURATION = :zoekt_call_duration
      ZOEKT_CALL_DETAILS = :zoekt_call_details

      class << self
        def get_request_count
          InstrumentationStorage[ZOEKT_REQUEST_COUNT] || 0
        end

        def increment_request_count
          InstrumentationStorage[ZOEKT_REQUEST_COUNT] ||= 0
          InstrumentationStorage[ZOEKT_REQUEST_COUNT] += 1
        end

        def detail_store
          InstrumentationStorage[ZOEKT_CALL_DETAILS] ||= []
        end

        def query_time
          query_time = InstrumentationStorage[ZOEKT_CALL_DURATION] || 0
          query_time.round(::Gitlab::InstrumentationHelper::DURATION_PRECISION)
        end

        def add_duration(duration)
          InstrumentationStorage[ZOEKT_CALL_DURATION] ||= 0
          InstrumentationStorage[ZOEKT_CALL_DURATION] += duration
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
