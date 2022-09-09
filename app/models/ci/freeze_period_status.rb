# frozen_string_literal: true

module Ci
  class FreezePeriodStatus
    attr_reader :project

    def initialize(project:)
      @project = project
    end

    def execute
      project.freeze_periods.any? { |period| within_freeze_period?(period) }
    end

    def within_freeze_period?(period)
      start_freeze_cron = Gitlab::Ci::CronParser.new(period.freeze_start, period.cron_timezone)
      end_freeze_cron = Gitlab::Ci::CronParser.new(period.freeze_end, period.cron_timezone)

      start_freeze = start_freeze_cron.previous_time_from(time_zone_now)
      end_freeze = end_freeze_cron.next_time_from(start_freeze)

      start_freeze <= time_zone_now && time_zone_now <= end_freeze
    end

    private

    def time_zone_now
      @time_zone_now ||= Time.zone.now
    end
  end
end
