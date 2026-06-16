# frozen_string_literal: true

module Gitlab
  module RapidDiffs
    class ServerTimings
      CLOCK = Process::CLOCK_MONOTONIC

      def initialize
        @metrics = {}
      end

      def measure(name)
        start = Process.clock_gettime(CLOCK)
        result = yield
        duration = Process.clock_gettime(CLOCK) - start
        @metrics[name] = (@metrics[name] || 0.0) + duration
        result
      end

      def to_html_attributes
        @metrics.map { |name, duration| "#{name}=\"#{duration.round(2)}\"" }.join(' ')
      end

      def to_server_timing_header
        @metrics.map { |name, duration| "#{name};dur=#{(duration * 1000).round(1)}" }.join(', ')
      end
    end
  end
end
