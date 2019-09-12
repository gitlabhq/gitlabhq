# frozen_string_literal: true

module Gitlab::UsageDataCounters
  class ProductivityAnalyticsCounter < BaseCounter
    KNOWN_EVENTS = %w[views].freeze
    PREFIX = 'productivity_analytics'
  end
end
