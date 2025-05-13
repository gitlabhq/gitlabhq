# frozen_string_literal: true

module Gitlab
  module Scheduling
    # Schedules another worker within the given time range using random splay.
    #
    # worker_class:
    #     The class name of the worker to be scheduled. REQUIRED.
    # within_minutes (1..59):
    #     The maximum number of minutes to wait before scheduling the worker. OPTIONAL.
    # within_hours (1..23):
    #     The maximum number of hours to wait before scheduling the worker. OPTIONAL.
    #
    # Example:
    #     # schedules MyWorker to run at a random time within the next 2 hours and 30 minutes
    #     Gitlab::Scheduling::ScheduleWithinWorker.perform_async({
    #         'worker_class' => 'MyWorker',
    #         'within_hours' => 2,
    #         'within_minutes' => 30
    #      })
    class ScheduleWithinWorker
      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- no relevant metadata

      feature_category :scalability
      data_consistency :sticky
      idempotent!

      def perform(args = {})
        validate_arguments!(args)

        worker_class = args['worker_class']&.constantize
        within_minutes = args['within_minutes'].to_i
        within_hours = args['within_hours'].to_i

        random_minute = within_minutes > 0 ? Random.rand(within_minutes + 1) : 0
        random_hour = within_hours > 0 ? Random.rand(within_hours + 1) : 0
        scheduled_for = (random_hour.hours + random_minute.minutes).from_now

        worker_class.perform_at(scheduled_for)

        log_hash_metadata_on_done({
          worker_class: worker_class.to_s,
          within_minutes: within_minutes,
          within_hours: within_hours,
          selected_minute: random_minute,
          selected_hour: random_hour,
          scheduled_for: scheduled_for
        })
      end

      private

      def validate_arguments!(args)
        raise ArgumentError, "worker_class is a required argument" unless args['worker_class']
        raise ArgumentError, "within_minutes must be nil or in [1..59]" unless valid_minute?(args['within_minutes'])
        raise ArgumentError, "within_hours must be nil or in [1..23]" unless valid_hour?(args['within_hours'])
      end

      def valid_minute?(minute)
        minute.nil? || (1..59).cover?(minute.to_i)
      end

      def valid_hour?(hour)
        hour.nil? || (1..23).cover?(hour.to_i)
      end
    end
  end
end
