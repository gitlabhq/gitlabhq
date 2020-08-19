# frozen_string_literal: true

module Gitlab
  module Analytics
    class UniqueVisits
      def track_visit(visitor_id, target_id, time = Time.zone.now)
        Gitlab::UsageDataCounters::HLLRedisCounter.track_event(visitor_id, target_id, time)
      end

      # Returns number of unique visitors for given targets in given time frame
      #
      # @param [String, Array[<String>]] targets ids of targets to count visits on. Special case for :any
      # @param [ActiveSupport::TimeWithZone] start_date start of time frame
      # @param [ActiveSupport::TimeWithZone] end_date end of time frame
      # @return [Integer] number of unique visitors
      def unique_visits_for(targets:, start_date: 7.days.ago, end_date: start_date + 1.week)
        target_ids = if targets == :analytics
                       self.class.analytics_ids
                     elsif targets == :compliance
                       self.class.compliance_ids
                     else
                       Array(targets)
                     end

        Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: target_ids, start_date: start_date, end_date: end_date)
      end

      class << self
        def analytics_ids
          Gitlab::UsageDataCounters::HLLRedisCounter.events_for_category('analytics')
        end

        def compliance_ids
          Gitlab::UsageDataCounters::HLLRedisCounter.events_for_category('compliance')
        end
      end
    end
  end
end
