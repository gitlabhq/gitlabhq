# frozen_string_literal: true

module Gitlab::UsageDataCounters
  class WikiPageCounter < BaseCounter
    KNOWN_EVENTS = %w[create update delete].freeze
    PREFIX = 'wiki_pages'
  end
end
