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
                    body: data.to_json,
                    headers: { 'Content-type' => 'application/json' }
                   )
    rescue HTTParty::Error => e
      Rails.logger.info "Unable to contact GitLab, Inc.: #{e}"
    end
  end

  def try_obtain_lease
    Gitlab::ExclusiveLease.new('gitlab_usage_ping_worker:ping', timeout: LEASE_TIMEOUT).try_obtain
  end

  def data
    usage_data = { version: Gitlab::VERSION,
                   active_user_count: current_active_user_count }
    license = License.current

    if license
      usage_data[:license_md5] = Digest::MD5.hexdigest(license.data)
      usage_data[:historical_max_users] = max_historical_user_count
      usage_data[:licensee] = license.licensee
      usage_data[:license_user_count] = license.user_count
      usage_data[:license_starts_at] = license.starts_at
      usage_data[:license_expires_at] = license.expires_at
      usage_data[:license_add_ons] = license.add_ons
      usage_data[:recorded_at] = Time.now
    end

    usage_data
  end

  def url
    'https://version.gitlab.com/usage_data'
  end
end
