# frozen_string_literal: true

module Gitlab::UsageDataCounters
  class BaseCounter
    extend RedisCounter

    UnknownEvent = Class.new(StandardError)

    class << self
      def redis_key(event)
        require_known_event(event)

        "USAGE_#{prefix}_#{event}".upcase
      end

      def count(event)
        increment(redis_key(event))
      end

      def read(event)
        total_count(redis_key(event))
      end

      def totals
        known_events.map { |event| [counter_key(event), read(event)] }.to_h
      end

      def fallback_totals
        known_events.map { |event| [counter_key(event), -1] }.to_h
      end

      private

      def require_known_event(event)
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(UnknownEvent.new, event: event) unless known_events.include?(event.to_s)
      end

      def counter_key(event)
        "#{prefix}_#{event}".to_sym
      end

      def known_events
        self::KNOWN_EVENTS
      end

      def prefix
        self::PREFIX
      end
    end
  end
end
