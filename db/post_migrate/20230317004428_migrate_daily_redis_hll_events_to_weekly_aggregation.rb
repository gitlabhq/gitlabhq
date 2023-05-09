# frozen_string_literal: true

class MigrateDailyRedisHllEventsToWeeklyAggregation < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    days_back = 29.days
    start_date = Date.today - days_back - 1.day
    end_date = Date.today + 1.day
    keys = {}

    Gitlab::UsageDataCounters::HLLRedisCounter.known_events.each do |event|
      next unless event[:aggregation].to_sym == :daily

      (start_date..end_date).each do |date|
        daily_key = redis_key(event, date, :daily)
        weekly_key = redis_key(event, date, :weekly)

        keys.key?(weekly_key) ? keys[weekly_key] << daily_key : keys[weekly_key] = [daily_key]
      end
    end

    keys.each do |weekly_key, daily_keys|
      Gitlab::Redis::SharedState.with do |redis|
        redis.pfmerge(weekly_key, *daily_keys)
        redis.expire(weekly_key, 6.weeks)
      end
    end
  end

  def down
    # no-op
  end

  # can't set daily key in HLLRedisCounter anymore, so need to duplicate logic here
  def redis_key(event, time, aggregation)
    key = "{hll_counters}_#{event[:name]}"
    if aggregation.to_sym == :daily
      year_day = time.strftime('%G-%j')
      "#{year_day}-#{key}"
    else
      year_week = time.strftime('%G-%V')
      "#{key}-#{year_week}"
    end
  end
end
