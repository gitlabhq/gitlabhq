# frozen_string_literal: true

module Gitlab::UsageDataCounters
  class SourceCodeCounter < BaseCounter
    KNOWN_EVENTS = %w[pushes].freeze
    PREFIX = 'source_code'
  end
end
