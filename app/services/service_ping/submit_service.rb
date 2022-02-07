# frozen_string_literal: true

module ServicePing
  class SubmitService
    PRODUCTION_BASE_URL = 'https://version.gitlab.com'
    STAGING_BASE_URL = 'https://gitlab-services-version-gitlab-com-staging.gs-staging.gitlab.org'
    USAGE_DATA_PATH = 'usage_data'
    ERROR_PATH = 'usage_ping_errors'

    SubmissionError = Class.new(StandardError)

    def initialize(skip_db_write: false)
      @skip_db_write = skip_db_write
    end

    def execute
      return unless ServicePing::ServicePingSettings.product_intelligence_enabled?

      start = Time.current
      begin
        usage_data = BuildPayloadService.new.execute
        response = submit_usage_data_payload(usage_data)
      rescue StandardError => e
        return unless Gitlab::CurrentSettings.usage_ping_enabled?

        error_payload = {
          time: Time.current,
          uuid: Gitlab::UsageData.add_metric('UuidMetric'),
          hostname: Gitlab::UsageData.add_metric('HostnameMetric'),
          version: Gitlab::UsageData.alt_usage_data { Gitlab::VERSION },
          message: e.message,
          elapsed: (Time.current - start).round(1)
        }
        submit_payload({ error: error_payload }, url: error_url)

        usage_data = Gitlab::Usage::ServicePingReport.for(mode: :values)
        response = submit_usage_data_payload(usage_data)
      end

      version_usage_data_id = response.dig('conv_index', 'usage_data_id') || response.dig('dev_ops_score', 'usage_data_id')

      unless version_usage_data_id.is_a?(Integer) && version_usage_data_id > 0
        raise SubmissionError, "Invalid usage_data_id in response: #{version_usage_data_id}"
      end

      unless @skip_db_write
        raw_usage_data = save_raw_usage_data(usage_data)
        raw_usage_data.update_version_metadata!(usage_data_id: version_usage_data_id)
        DevopsReportService.new(response).execute
      end
    end

    def url
      URI.join(base_url, USAGE_DATA_PATH)
    end

    def error_url
      URI.join(base_url, ERROR_PATH)
    end

    private

    def submit_payload(payload, url: self.url)
      Gitlab::HTTP.post(
        url,
        body: payload.to_json,
        allow_local_requests: true,
        headers: { 'Content-type' => 'application/json' }
      )
    end

    def submit_usage_data_payload(usage_data)
      raise SubmissionError, 'Usage data is blank' if usage_data.blank?

      response = submit_payload(usage_data)

      raise SubmissionError, "Unsuccessful response code: #{response.code}" unless response.success?

      response
    end

    def save_raw_usage_data(usage_data)
      RawUsageData.safe_find_or_create_by(recorded_at: usage_data[:recorded_at]) do |record|
        record.payload = usage_data
      end
    end

    # See https://gitlab.com/gitlab-org/gitlab/-/issues/233615 for details
    def base_url
      Rails.env.production? ? PRODUCTION_BASE_URL : STAGING_BASE_URL
    end
  end
end

ServicePing::SubmitService.prepend_mod
