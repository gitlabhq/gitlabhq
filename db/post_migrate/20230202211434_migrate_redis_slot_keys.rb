# frozen_string_literal: true

class MigrateRedisSlotKeys < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    BackupHLLRedisCounter.known_events.each do |event|
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
    days_back = BackupHLLRedisCounter::DEFAULT_DAILY_KEY_EXPIRY_LENGTH
    start_date = Date.today - days_back - 1.day
    end_date = Date.today + 1.day

    (start_date..end_date).each do |date|
      rename_key(event, date)
    end
  end

  def migrate_weekly_aggregated(event)
    weeks_back = BackupHLLRedisCounter::DEFAULT_WEEKLY_KEY_EXPIRY_LENGTH
    start_date = (Date.today - weeks_back).beginning_of_week - 1.day
    end_date = Date.today.end_of_week + 1.day

    (start_date..end_date).each { |date| rename_key(event, date) }
  end

  def rename_key(event, date)
    old_key = old_redis_key(event, date)
    new_key = BackupHLLRedisCounter.redis_key(event, date)

    # cannot simply rename due to different slots
    Gitlab::Redis::SharedState.with do |r|
      break unless r.exists?(old_key)

      Gitlab::Redis::HLL.add(
        key: new_key,
        value: r.pfcount(old_key),
        expiry: r.ttl(old_key)
      )
    end
  end

  def old_redis_key(event, time)
    name_with_slot = if event[:redis_slot].present?
                       event[:name].to_s.gsub(event[:redis_slot], "{#{event[:redis_slot]}}")
                     else
                       "{#{event[:name]}}"
                     end

    BackupHLLRedisCounter.apply_time_aggregation(name_with_slot, time, event)
  end

  # :nocov:  Existing backed up class # rubocop:disable Gitlab/NoCodeCoverageComment
  module BackupHLLRedisCounter
    DEFAULT_WEEKLY_KEY_EXPIRY_LENGTH = 6.weeks
    DEFAULT_DAILY_KEY_EXPIRY_LENGTH = 29.days
    REDIS_SLOT = 'hll_counters'

    KNOWN_EVENTS_PATH = File.expand_path('known_events/*.yml', __dir__)
    ALLOWED_AGGREGATIONS = %i[daily weekly].freeze

    class << self
      def known_events
        @known_events ||= load_events(KNOWN_EVENTS_PATH)
      end

      def load_events(wildcard)
        Dir[wildcard].each_with_object([]) do |path, events|
          events.push(*load_yaml_from_path(path))
        end
      end

      def load_yaml_from_path(path)
        YAML.safe_load(File.read(path))&.map(&:with_indifferent_access)
      end

      def known_events_names
        known_events.map { |event| event[:name] } # rubocop:disable Rails/Pluck
      end

      def redis_key(event, time, context = '')
        key = "{#{REDIS_SLOT}}_#{event[:name]}"
        key = apply_time_aggregation(key, time, event)
        key = "#{context}_#{key}" if context.present?
        key
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
  end
  # :nocov: # rubocop:disable Gitlab/NoCodeCoverageComment
end
