# frozen_string_literal: true

module UserStatusCleanup
  # This worker will run every minute to look for user status records to clean up.
  class BatchWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    # rubocop:disable Scalability/CronWorkerContext
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    feature_category :users
    tags :exclude_from_kubernetes

    idempotent!

    # Avoid running too many UPDATE queries at once
    MAX_RUNTIME = 30.seconds

    def perform
      return unless UserStatus.scheduled_for_cleanup.exists?

      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      loop do
        result = Users::BatchStatusCleanerService.execute
        break if result[:deleted_rows] < Users::BatchStatusCleanerService::BATCH_SIZE

        current_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        break if (current_time - start_time) > MAX_RUNTIME
      end
    end
  end
end
