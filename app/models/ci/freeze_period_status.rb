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
      # previous_freeze_end, ..., previous_freeze_start, ..., NOW, ..., next_freeze_end, ..., next_freeze_start
      # Current time is within a freeze period if
      # it falls between a previous freeze start and next freeze end
      start_freeze = Gitlab::Ci::CronParser.new(period.freeze_start, period.cron_timezone)
      end_freeze = Gitlab::Ci::CronParser.new(period.freeze_end, period.cron_timezone)

      previous_freeze_start = previous_time(start_freeze)
      previous_freeze_end = previous_time(end_freeze)
      next_freeze_start = next_time(start_freeze)
      next_freeze_end = next_time(end_freeze)

      previous_freeze_end < previous_freeze_start &&
        previous_freeze_start <= time_zone_now &&
        time_zone_now <= next_freeze_end &&
        next_freeze_end < next_freeze_start
    end

    private

    def previous_time(cron_parser)
      cron_parser.previous_time_from(time_zone_now)
    end

    def next_time(cron_parser)
      cron_parser.next_time_from(time_zone_now)
    end

    def time_zone_now
      @time_zone_now ||= Time.zone.now
    end
  end
end
