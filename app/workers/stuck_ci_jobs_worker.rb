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

  def perform
    Ci::StuckBuilds::DropRunningWorker.perform_in(20.minutes)
    Ci::StuckBuilds::DropScheduledWorker.perform_in(40.minutes)

    try_obtain_lease do
      Ci::StuckBuilds::DropPendingService.new.execute
    end
  end

  private

  def lease_timeout
    30.minutes
  end
end
