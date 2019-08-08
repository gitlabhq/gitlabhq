# frozen_string_literal: true

module Gitlab::UsageDataCounters
  class SnippetCounter < BaseCounter
    KNOWN_EVENTS = %w[create update].freeze
    PREFIX = 'snippet'
  end
end
