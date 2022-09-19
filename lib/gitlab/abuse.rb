# frozen_string_literal: true

module Gitlab
  module Abuse
    CONFIDENCE_LEVELS = {
      certain: 1.0,
      likely: 0.8,
      uncertain: 0.5,
      unknown: 0.0
    }.freeze

    class << self
      def confidence(rating)
        CONFIDENCE_LEVELS.fetch(rating.to_sym)
      end
    end
  end
end
