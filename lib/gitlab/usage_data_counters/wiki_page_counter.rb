# frozen_string_literal: true

module Gitlab::UsageDataCounters
  class WikiPageCounter
    extend RedisCounter

    KNOWN_EVENTS = %w[create update delete].map(&:freeze).freeze

    UnknownEvent = Class.new(StandardError)

    class << self
      # Each event gets a unique Redis key
      def redis_key(event)
        raise UnknownEvent, event unless KNOWN_EVENTS.include?(event.to_s)

        "USAGE_WIKI_PAGES_#{event}".upcase
      end

      def count(event)
        increment(redis_key event)
      end

      def read(event)
        total_count(redis_key event)
      end

      def totals
        KNOWN_EVENTS.map { |e| ["wiki_pages_#{e}".to_sym, read(e)] }.to_h
      end
    end
  end
end
