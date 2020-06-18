# frozen_string_literal: true

module Gitlab::UsageDataCounters
  class DesignsCounter
    extend Gitlab::UsageDataCounters::RedisCounter

    KNOWN_EVENTS = %w[create update delete].freeze

    UnknownEvent = Class.new(StandardError)

    class << self
      # Each event gets a unique Redis key
      def redis_key(event)
        raise UnknownEvent, event unless KNOWN_EVENTS.include?(event.to_s)

        "USAGE_DESIGN_MANAGEMENT_DESIGNS_#{event}".upcase
      end

      def count(event)
        increment(redis_key(event))
      end

      def read(event)
        total_count(redis_key(event))
      end

      def totals
        KNOWN_EVENTS.map { |event| [counter_key(event), read(event)] }.to_h
      end

      def fallback_totals
        KNOWN_EVENTS.map { |event| [counter_key(event), -1] }.to_h
      end

      private

      def counter_key(event)
        "design_management_designs_#{event}".to_sym
      end
    end
  end
end
