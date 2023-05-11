# frozen_string_literal: true

module Gitlab
  module RuggedInstrumentation
    InstrumentationStorage = ::Gitlab::Instrumentation::Storage

    def self.query_time
      query_time = InstrumentationStorage[:rugged_query_time] || 0
      query_time.round(Gitlab::InstrumentationHelper::DURATION_PRECISION)
    end

    def self.add_query_time(duration)
      InstrumentationStorage[:rugged_query_time] ||= 0
      InstrumentationStorage[:rugged_query_time] += duration
    end

    def self.query_time_ms
      (self.query_time * 1000).round(2)
    end

    def self.query_count
      InstrumentationStorage[:rugged_call_count] ||= 0
    end

    def self.increment_query_count
      InstrumentationStorage[:rugged_call_count] ||= 0
      InstrumentationStorage[:rugged_call_count] += 1
    end

    def self.active?
      InstrumentationStorage.active?
    end

    def self.add_call_details(details)
      return unless Gitlab::PerformanceBar.enabled_for_request?

      InstrumentationStorage[:rugged_call_details] ||= []
      InstrumentationStorage[:rugged_call_details] << details
    end

    def self.list_call_details
      return [] unless Gitlab::PerformanceBar.enabled_for_request?

      InstrumentationStorage[:rugged_call_details] || []
    end
  end
end
