# frozen_string_literal: true

class StuckCiJobsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  # rubocop:disable Scalability/CronWorkerContext
  # This is an instance-wide cleanup query, so there's no meaningful
  # scope to consider this in the context of.
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext

  data_consistency :always

  feature_category :continuous_integration
  worker_resource_boundary :cpu

  EXCLUSIVE_LEASE_KEY = 'stuck_ci_builds_worker_lease'

  def perform
    Ci::StuckBuilds::DropRunningWorker.perform_in(20.minutes)

    return unless try_obtain_lease

    Ci::StuckBuilds::DropService.new.execute

    remove_lease
  end

  private

  def try_obtain_lease
    @uuid = Gitlab::ExclusiveLease.new(EXCLUSIVE_LEASE_KEY, timeout: 30.minutes).try_obtain
  end

  def remove_lease
    Gitlab::ExclusiveLease.cancel(EXCLUSIVE_LEASE_KEY, @uuid)
  end
end
