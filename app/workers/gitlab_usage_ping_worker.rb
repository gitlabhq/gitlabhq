# frozen_string_literal: true

class GitlabUsagePingWorker # rubocop:disable Scalability/IdempotentWorker
  LEASE_KEY = 'gitlab_usage_ping_worker:ping'
  LEASE_TIMEOUT = 86400

  include ApplicationWorker
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext
  include Gitlab::ExclusiveLeaseHelpers

  feature_category :usage_ping
  sidekiq_options retry: 3, dead: false
  sidekiq_retry_in { |count| (count + 1) * 8.hours.to_i }

  def perform
    # Disable usage ping for GitLab.com
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/292929 for details
    return if Gitlab.com?

    # Multiple Sidekiq workers could run this. We should only do this at most once a day.
    in_lock(LEASE_KEY, ttl: LEASE_TIMEOUT) do
      # Splay the request over a minute to avoid thundering herd problems.
      sleep(rand(0.0..60.0).round(3))

      ServicePing::SubmitService.new.execute
    end
  end
end
