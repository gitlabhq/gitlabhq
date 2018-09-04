class ClearSharedRunnersMinutesWorker
  LEASE_TIMEOUT = 3600

  include ApplicationWorker
  include CronjobQueue

  # rubocop: disable CodeReuse/ActiveRecord
  def perform
    return unless try_obtain_lease

    NamespaceStatistics.where.not(shared_runners_seconds: 0)
      .update_all(
        shared_runners_seconds: 0,
        shared_runners_seconds_last_reset: Time.now)

    ProjectStatistics.where.not(shared_runners_seconds: 0)
      .update_all(
        shared_runners_seconds: 0,
        shared_runners_seconds_last_reset: Time.now)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def try_obtain_lease
    Gitlab::ExclusiveLease.new('gitlab_clear_shared_runners_minutes_worker',
      timeout: LEASE_TIMEOUT).try_obtain
  end
end
