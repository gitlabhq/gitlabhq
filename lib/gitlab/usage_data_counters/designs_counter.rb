# frozen_string_literal: true

module Gitlab::UsageDataCounters
  class DesignsCounter < BaseCounter
    KNOWN_EVENTS = %w[create update delete].freeze
    PREFIX = 'design_management_designs'
  end
end
