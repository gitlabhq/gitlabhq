# frozen_string_literal: true

module Gitlab::UsageDataCounters
  class CycleAnalyticsCounter < BaseCounter
    KNOWN_EVENTS = %w[views].freeze
    PREFIX = 'cycle_analytics'
  end
end
