# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    COUNTERS = [
      DiffsCounter,
      MergeRequestWidgetExtensionCounter
    ].freeze

    UsageDataCounterError = Class.new(StandardError)
    UnknownEvent = Class.new(UsageDataCounterError)

    class << self
      def counters
        COUNTERS
      end

      def count(event_name)
        counters.each do |counter|
          event = counter.fetch_supported_event(event_name)

          return counter.count(event) if event
        end

        raise UnknownEvent, "Cannot find counter for event #{event_name}"
      end
    end
  end
end

Gitlab::UsageDataCounters.prepend_mod_with('Gitlab::UsageDataCounters')
