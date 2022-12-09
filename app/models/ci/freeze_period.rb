# frozen_string_literal: true

module Ci
  class FreezePeriod < Ci::ApplicationRecord
    include StripAttribute
    include Ci::NamespacedModelName
    include Gitlab::Utils::StrongMemoize

    STATUS_ACTIVE = :active
    STATUS_INACTIVE = :inactive

    default_scope { order(created_at: :asc) } # rubocop:disable Cop/DefaultScope

    belongs_to :project, inverse_of: :freeze_periods

    strip_attributes! :freeze_start, :freeze_end

    validates :freeze_start, cron: true, presence: true
    validates :freeze_end, cron: true, presence: true
    validates :cron_timezone, cron_freeze_period_timezone: true, presence: true

    def active?
      status == STATUS_ACTIVE
    end

    def status
      Gitlab::SafeRequestStore.fetch("ci:freeze_period:#{id}:status") do
        within_freeze_period? ? STATUS_ACTIVE : STATUS_INACTIVE
      end
    end

    def time_start
      Gitlab::SafeRequestStore.fetch("ci:freeze_period:#{id}:time_start") do
        freeze_start_parsed_cron.previous_time_from(time_zone_now)
      end
    end

    def next_time_start
      Gitlab::SafeRequestStore.fetch("ci:freeze_period:#{id}:next_time_start") do
        freeze_start_parsed_cron.next_time_from(time_zone_now)
      end
    end

    def time_end_from_now
      Gitlab::SafeRequestStore.fetch("ci:freeze_period:#{id}:time_end_from_now") do
        freeze_end_parsed_cron.next_time_from(time_zone_now)
      end
    end

    def time_end_from_start
      Gitlab::SafeRequestStore.fetch("ci:freeze_period:#{id}:time_end_from_start") do
        freeze_end_parsed_cron.next_time_from(time_start)
      end
    end

    private

    def within_freeze_period?
      time_start <= time_zone_now && time_zone_now <= time_end_from_start
    end

    def freeze_start_parsed_cron
      Gitlab::Ci::CronParser.new(freeze_start, cron_timezone)
    end
    strong_memoize_attr :freeze_start_parsed_cron

    def freeze_end_parsed_cron
      Gitlab::Ci::CronParser.new(freeze_end, cron_timezone)
    end
    strong_memoize_attr :freeze_end_parsed_cron

    def time_zone_now
      Time.zone.now
    end
    strong_memoize_attr :time_zone_now
  end
end
