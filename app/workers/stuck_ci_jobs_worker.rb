# frozen_string_literal: true

class StuckCiJobsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include ExclusiveLeaseGuard

  # rubocop:disable Scalability/CronWorkerContext
  # This is an instance-wide cleanup query, so there's no meaningful
  # scope to consider this in the context of.
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext

  data_consistency :always

  feature_category :continuous_integration

  MINUTES_BETWEEN_RUNS = 60 # how often this worker is run via cron

  def perform
    perform_staggered_work

    try_obtain_lease do
      Ci::StuckBuilds::DropPendingService.new.execute
    end
  end

  private

  def perform_staggered_work
    delayed_workers = [
      Ci::StuckBuilds::DropRunningWorker,
      Ci::StuckBuilds::DropScheduledWorker,
      Ci::StuckBuilds::DropCancelingWorker
    ]

    # We run this worker every hour and want to stagger the load on the builds table
    # cron job interval / number of workers or services executed
    interval = (MINUTES_BETWEEN_RUNS / (delayed_workers.size + 1))

    delayed_workers.each_with_index do |worker, index|
      run_at = (index + 1) * interval
      worker.perform_in(run_at.minutes)
    end
  end

  def lease_timeout
    30.minutes
  end
end
