# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class SearchCounter < BaseCounter
      KNOWN_EVENTS = %w[all_searches navbar_searches].freeze

      class << self
        def redis_key(event)
          require_known_event(event)

          "#{event}_COUNT".upcase
        end

        private

        def counter_key(event)
          "#{event}".to_sym
        end
      end
    end
  end
end
