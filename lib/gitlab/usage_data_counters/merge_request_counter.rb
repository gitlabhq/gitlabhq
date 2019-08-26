# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class MergeRequestCounter < BaseCounter
      KNOWN_EVENTS = %w[create].freeze
      PREFIX = 'merge_request'
    end
  end
end
