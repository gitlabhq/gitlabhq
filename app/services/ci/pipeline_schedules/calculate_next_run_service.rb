# frozen_string_literal: true

module Ci
  module PipelineSchedules
    class CalculateNextRunService < BaseService
      include Gitlab::Utils::StrongMemoize

      def execute(schedule, fallback_method:)
        @schedule = schedule

        return fallback_method.call unless plan_cron&.cron_valid?

        now = Time.zone.now
        plan_min_run = plan_cron.next_time_from(now)

        schedule_next_run = schedule_cron.next_time_from(now)
        return schedule_next_run if worker_cron.match?(schedule_next_run) && plan_min_run <= schedule_next_run

        plan_next_run = plan_cron.next_time_from(schedule_next_run)
        return plan_next_run if worker_cron.match?(plan_next_run)

        worker_next_run = worker_cron.next_time_from(schedule_next_run)
        return worker_next_run if plan_min_run <= worker_next_run

        worker_cron.next_time_from(plan_next_run)
      end

      private

      def schedule_cron
        strong_memoize(:schedule_cron) do
          Gitlab::Ci::CronParser.new(@schedule.cron, @schedule.cron_timezone)
        end
      end

      def worker_cron
        strong_memoize(:worker_cron) do
          Gitlab::Ci::CronParser.new(@schedule.worker_cron_expression, Time.zone.name)
        end
      end

      def plan_cron
        strong_memoize(:plan_cron) do
          daily_limit = @schedule.daily_limit

          next unless daily_limit

          every_x_minutes = (1.day.in_minutes / daily_limit).to_i

          begin
            Gitlab::Ci::CronParser.parse_natural("every #{every_x_minutes} minutes", Time.zone.name)
          rescue ZeroDivisionError
            # Fugit returns ZeroDivision Error if provided a number
            # less than 1 in the expression.
            nil
          end
        end
      end
    end
  end
end
