# frozen_string_literal: true

class ReMigrateRedisSlotKeys < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    Gitlab::UsageDataCounters::HLLRedisCounter.known_events.each do |event|
      if event[:aggregation].to_sym == :daily
        migrate_daily_aggregated(event)
      else
        migrate_weekly_aggregated(event)
      end
    end
  end

  def down
    # no-op
  end

  private

  def migrate_daily_aggregated(event)
    days_back = Gitlab::UsageDataCounters::HLLRedisCounter::DEFAULT_DAILY_KEY_EXPIRY_LENGTH
    start_date = Date.today - days_back - 1.day
    end_date = Date.today + 1.day

    (start_date..end_date).each do |date|
      rename_key(event, date)
    end
  end

  def migrate_weekly_aggregated(event)
    weeks_back = Gitlab::UsageDataCounters::HLLRedisCounter::DEFAULT_WEEKLY_KEY_EXPIRY_LENGTH
    start_date = (Date.today - weeks_back).beginning_of_week - 1.day
    end_date = Date.today.end_of_week + 1.day

    (start_date..end_date).step(7).each { |date| rename_key(event, date) }
  end

  def rename_key(event, date)
    old_key = old_redis_key(event, date)
    new_key = new_redis_key(event, date)

    # cannot simply rename due to different slots
    Gitlab::Redis::SharedState.with do |redis|
      hll_blob = redis.get(old_key)

      break unless hll_blob

      temp_key = new_key + "_#{Time.current.to_i}"
      ttl = redis.ttl(old_key)
      ttl = ttl > 0 ? ttl : Gitlab::UsageDataCounters::HLLRedisCounter.send(:expiry, event)

      redis.multi do |multi|
        multi.set(temp_key, hll_blob, ex: 1.day.to_i)
        multi.pfmerge(new_key, new_key, temp_key)
        multi.expire(new_key, ttl)
      end

      redis.del(temp_key)
    end
  end

  def old_redis_key(event, time)
    name_with_slot = if event[:redis_slot].present?
                       event[:name].to_s.gsub(event[:redis_slot], "{#{event[:redis_slot]}}")
                     else
                       "{#{event[:name]}}"
                     end

    apply_time_aggregation(name_with_slot, time, event)
  end

  def new_redis_key(event, time)
    key = "{hll_counters}_#{event[:name]}"
    apply_time_aggregation(key, time, event)
  end

  def apply_time_aggregation(key, time, event)
    if event[:aggregation].to_sym == :daily
      year_day = time.strftime('%G-%j')
      "#{year_day}-#{key}"
    else
      year_week = time.strftime('%G-%V')
      "#{key}-#{year_week}"
    end
  end
end
