# frozen_string_literal: true

class GitlabUsagePingWorker
  LEASE_TIMEOUT = 86400

  include ApplicationWorker
  include CronjobQueue
  include ExclusiveLeaseGuard

  def perform
    try_obtain_lease do
      SubmitUsagePingService.new.execute
    end rescue LeaseNotObtained
  end

  private

  def lease_key
    'gitlab_usage_ping_worker:ping'
  end

  def lease_timeout
    LEASE_TIMEOUT
  end
end
