# frozen_string_literal: true

module Gitlab
  module Analytics
    class UniqueVisits
      TARGET_IDS = Set[
        'g_analytics_contribution',
        'g_analytics_insights',
        'g_analytics_issues',
        'g_analytics_productivity',
        'g_analytics_valuestream',
        'p_analytics_pipelines',
        'p_analytics_code_reviews',
        'p_analytics_valuestream',
        'p_analytics_insights',
        'p_analytics_issues',
        'p_analytics_repo',
        'i_analytics_cohorts',
        'i_analytics_dev_ops_score'
      ].freeze

      KEY_EXPIRY_LENGTH = 12.weeks

      def track_visit(visitor_id, target_id, time = Time.zone.now)
        target_key = key(target_id, time)

        Gitlab::Redis::HLL.add(key: target_key, value: visitor_id, expiry: KEY_EXPIRY_LENGTH)
      end

      # Returns number of unique visitors for given targets in given time frame
      #
      # @param [String, Array[<String>]] targets ids of targets to count visits on. Special case for :any
      # @param [ActiveSupport::TimeWithZone] start_week start of time frame
      # @param [Integer] weeks time frame length in weeks
      # @return [Integer] number of unique visitors
      def unique_visits_for(targets:, start_week: 7.days.ago, weeks: 1)
        target_ids = if targets == :any
                       TARGET_IDS
                     else
                       Array(targets)
                     end

        timeframe_start = [start_week, weeks.weeks.ago].min

        redis_keys = keys(targets: target_ids, timeframe_start: timeframe_start, weeks: weeks)

        Gitlab::Redis::HLL.count(keys: redis_keys)
      end

      private

      def key(target_id, time)
        raise "Invalid target id #{target_id}" unless TARGET_IDS.include?(target_id.to_s)

        target_key = target_id.to_s.gsub('analytics', '{analytics}')
        year_week = time.strftime('%G-%V')

        "#{target_key}-#{year_week}"
      end

      def keys(targets:, timeframe_start:, weeks:)
        (0..(weeks - 1)).map do |week_increment|
          targets.map { |target_id| key(target_id, timeframe_start + week_increment * 7.days) }
        end.flatten
      end
    end
  end
end
