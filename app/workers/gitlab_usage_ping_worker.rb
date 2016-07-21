class GitlabUsagePingWorker
  LEASE_TIMEOUT = 86400

  include LicenseHelper
  include Sidekiq::Worker
  include HTTParty

  # This is not guaranteed to succeed, so don't retry on failure
  sidekiq_options queue: :default, retry: false

  def perform
    return unless current_application_settings.usage_ping_enabled

    # Multiple Sidekiq workers could run this. We should only do this at most once a day.
    return unless try_obtain_lease

    begin
      HTTParty.post(url,
                    body: license_usage_data.to_json,
                    headers: { 'Content-type' => 'application/json' }
                   )
    rescue HTTParty::Error => e
      Rails.logger.info "Unable to contact GitLab, Inc.: #{e}"
    end
  end

  def try_obtain_lease
    Gitlab::ExclusiveLease.new('gitlab_usage_ping_worker:ping', timeout: LEASE_TIMEOUT).try_obtain
  end

  def url
    'https://version.gitlab.com/usage_data'
  end
end
