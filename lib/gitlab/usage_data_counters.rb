# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    COUNTERS = [
      WikiPageCounter,
      WebIdeCounter,
      NoteCounter,
      SnippetCounter,
      SearchCounter,
      CycleAnalyticsCounter,
      ProductivityAnalyticsCounter,
      SourceCodeCounter,
      MergeRequestCounter,
      DesignsCounter,
      KubernetesAgentCounter,
      DiffsCounter,
      ServiceUsageDataCounter,
      MergeRequestWidgetExtensionCounter
    ].freeze

    COUNTERS_MIGRATED_TO_INSTRUMENTATION_CLASSES = [
      PackageEventCounter
    ].freeze

    UsageDataCounterError = Class.new(StandardError)
    UnknownEvent = Class.new(UsageDataCounterError)

    class << self
      def unmigrated_counters
        # we are using the #counters method instead of the COUNTERS const
        # to make sure it's working correctly for `ee` version of UsageDataCounters
        counters - self::COUNTERS_MIGRATED_TO_INSTRUMENTATION_CLASSES
      end

      def counters
        self::COUNTERS + self::COUNTERS_MIGRATED_TO_INSTRUMENTATION_CLASSES
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
