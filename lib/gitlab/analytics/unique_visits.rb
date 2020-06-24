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
        'u_analytics_todos',
        'i_analytics_cohorts',
        'i_analytics_dev_ops_score'
      ].freeze

      KEY_EXPIRY_LENGTH = 28.days

      def track_visit(visitor_id, target_id, time = Time.zone.now)
        target_key = key(target_id, time)

        Gitlab::Redis::SharedState.with do |redis|
          redis.multi do |multi|
            multi.pfadd(target_key, visitor_id)
            multi.expire(target_key, KEY_EXPIRY_LENGTH)
          end
        end
      end

      def weekly_unique_visits_for_target(target_id, week_of: 7.days.ago)
        Gitlab::Redis::SharedState.with do |redis|
          redis.pfcount(key(target_id, week_of))
        end
      end

      def weekly_unique_visits_for_any_target(week_of: 7.days.ago)
        keys = TARGET_IDS.map { |target_id| key(target_id, week_of) }

        Gitlab::Redis::SharedState.with do |redis|
          Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
            redis.pfcount(*keys)
          end
        end
      end

      private

      def key(target_id, time)
        raise "Invalid target id #{target_id}" unless TARGET_IDS.include?(target_id.to_s)

        year_week = time.strftime('%G-%V')
        "#{target_id}-#{year_week}"
      end
    end
  end
end
