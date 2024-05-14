# frozen_string_literal: true

class GitlabServicePingWorker # rubocop:disable Scalability/IdempotentWorker
  LEASE_KEY = 'gitlab_service_ping_worker:ping'
  LEASE_TIMEOUT = 86400

  include ApplicationWorker

  data_consistency :always
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext
  include Gitlab::ExclusiveLeaseHelpers

  feature_category :service_ping
  worker_resource_boundary :cpu
  sidekiq_options retry: 3, dead: false
  sidekiq_retry_in { |count| (count + 1) * 8.hours.to_i }

  def perform(options = {})
    # Sidekiq does not support keyword arguments, so the args need to be
    # passed the old pre-Ruby 2.0 way.
    #
    # See https://github.com/mperham/sidekiq/issues/2372
    triggered_from_cron = options.fetch('triggered_from_cron', true)
    skip_db_write = options.fetch('skip_db_write', false)

    # Disable service ping for GitLab.com unless called manually
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/292929 for details
    return if Gitlab.com? && triggered_from_cron

    # Multiple Sidekiq workers could run this. We should only do this at most once a day.
    in_lock(LEASE_KEY, ttl: LEASE_TIMEOUT) do
      # Splay the request over a minute to avoid thundering herd problems.
      sleep(rand(0.0..60.0).round(3))

      ServicePing::SubmitService.new(payload: usage_data, skip_db_write: skip_db_write).execute
    end
  end

  def usage_data
    ServicePing::BuildPayload.new.execute.tap do |payload|
      record = {
        recorded_at: payload[:recorded_at],
        payload: payload,
        created_at: Time.current,
        updated_at: Time.current,
        organization_id: Organizations::Organization::DEFAULT_ORGANIZATION_ID
      }

      RawUsageData.upsert(record, unique_by: :recorded_at)
    end
  rescue StandardError => err
    Gitlab::ErrorTracking.track_and_raise_for_dev_exception(err)
    nil
  end
end

GitlabServicePingWorker.prepend_mod
