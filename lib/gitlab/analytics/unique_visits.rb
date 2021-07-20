# frozen_string_literal: true

module Gitlab
  module Analytics
    class UniqueVisits
      # Returns number of unique visitors for given targets in given time frame
      #
      # @param [String, Array[<String>]] targets ids of targets to count visits on. Special case for :any
      # @param [ActiveSupport::TimeWithZone] start_date start of time frame
      # @param [ActiveSupport::TimeWithZone] end_date end of time frame
      # @return [Integer] number of unique visitors
      def unique_visits_for(targets:, start_date: 7.days.ago, end_date: start_date + 1.week)
        events = if targets == :analytics
                   self.class.analytics_events
                 elsif targets == :compliance
                   self.class.compliance_events
                 else
                   Array(targets)
                 end

        Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: events, start_date: start_date, end_date: end_date)
      end

      class << self
        def analytics_events
          Gitlab::UsageDataCounters::HLLRedisCounter.events_for_category('analytics')
        end

        def compliance_events
          Gitlab::UsageDataCounters::HLLRedisCounter.events_for_category('compliance')
        end
      end
    end
  end
end
