# frozen_string_literal: true

module Gitlab::UsageDataCounters
  class NoteCounter < BaseCounter
    KNOWN_EVENTS = %w[create].freeze
    PREFIX = 'note'
    COUNTABLE_TYPES = %w[Snippet].freeze

    class << self
      def redis_key(event, noteable_type)
        "#{super(event)}_#{noteable_type}".upcase
      end

      def count(event, noteable_type)
        return unless countable?(noteable_type)

        increment(redis_key(event, noteable_type))
      end

      def read(event, noteable_type)
        return 0 unless countable?(noteable_type)

        total_count(redis_key(event, noteable_type))
      end

      def totals
        {
          snippet_comment: read(:create, 'Snippet')
        }
      end

      private

      def countable?(noteable_type)
        COUNTABLE_TYPES.include?(noteable_type.to_s)
      end
    end
  end
end
