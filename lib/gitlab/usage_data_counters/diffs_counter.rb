# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class DiffsCounter < BaseCounter
      KNOWN_EVENTS = %w[searches].freeze
      PREFIX = 'diff'
    end
  end
end
