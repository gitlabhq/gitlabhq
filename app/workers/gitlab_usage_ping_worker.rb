# frozen_string_literal: true

class GitlabUsagePingWorker
  LEASE_TIMEOUT = 86400

  include ApplicationWorker
  include CronjobQueue

  feature_category_not_owned!

  # Retry for up to approximately three hours then give up.
  sidekiq_options retry: 10, dead: false

  def perform
    # Multiple Sidekiq workers could run this. We should only do this at most once a day.
    return unless try_obtain_lease

    # Splay the request over a minute to avoid thundering herd problems.
    sleep(rand(0.0..60.0).round(3))

    SubmitUsagePingService.new.execute
  end

  private

  def try_obtain_lease
    Gitlab::ExclusiveLease.new('gitlab_usage_ping_worker:ping', timeout: LEASE_TIMEOUT).try_obtain
  end
end
