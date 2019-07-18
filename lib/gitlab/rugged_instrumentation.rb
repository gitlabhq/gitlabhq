# frozen_string_literal: true

module Gitlab
  module RuggedInstrumentation
    def self.query_time
      SafeRequestStore[:rugged_query_time] ||= 0
    end

    def self.query_time=(duration)
      SafeRequestStore[:rugged_query_time] = duration
    end

    def self.query_time_ms
      (self.query_time * 1000).round(2)
    end

    def self.query_count
      SafeRequestStore[:rugged_call_count] ||= 0
    end

    def self.increment_query_count
      SafeRequestStore[:rugged_call_count] ||= 0
      SafeRequestStore[:rugged_call_count] += 1
    end

    def self.active?
      Gitlab::SafeRequestStore.active?
    end
  end
end
