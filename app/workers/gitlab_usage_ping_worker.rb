class GitlabUsagePingWorker
  LEASE_TIMEOUT = 86400

  include ApplicationWorker
  include CronjobQueue

  def perform
    # Multiple Sidekiq workers could run this. We should only do this at most once a day.
    return unless try_obtain_lease

    SubmitUsagePingService.new.execute
  end

  private

  def try_obtain_lease
    Gitlab::ExclusiveLease.new('gitlab_usage_ping_worker:ping', timeout: LEASE_TIMEOUT).try_obtain
  end
end
