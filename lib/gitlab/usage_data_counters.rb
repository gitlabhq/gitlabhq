# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    COUNTERS = [
      NoteCounter,
      SearchCounter,
      KubernetesAgentCounter,
      MergeRequestWidgetExtensionCounter
    ].freeze

    COUNTERS_MIGRATED_TO_INSTRUMENTATION_CLASSES = [
      PackageEventCounter,
      MergeRequestCounter,
      DesignsCounter,
      DiffsCounter,
      ServiceUsageDataCounter,
      WebIdeCounter,
      WikiPageCounter,
      SnippetCounter,
      CycleAnalyticsCounter,
      ProductivityAnalyticsCounter,
      SourceCodeCounter
    ].freeze

    UsageDataCounterError = Class.new(StandardError)
    UnknownEvent = Class.new(UsageDataCounterError)

    class << self
      def unmigrated_counters
        self::COUNTERS
      end

      def counters
        unmigrated_counters + migrated_counters
      end

      def count(event_name)
        counters.each do |counter|
          event = counter.fetch_supported_event(event_name)

          return counter.count(event) if event
        end

        raise UnknownEvent, "Cannot find counter for event #{event_name}"
      end

      private

      def migrated_counters
        COUNTERS_MIGRATED_TO_INSTRUMENTATION_CLASSES
      end
    end
  end
end

Gitlab::UsageDataCounters.prepend_mod_with('Gitlab::UsageDataCounters')
