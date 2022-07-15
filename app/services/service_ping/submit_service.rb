# frozen_string_literal: true

module ServicePing
  class SubmitService
    PRODUCTION_BASE_URL = 'https://version.gitlab.com'
    STAGING_BASE_URL = 'https://gitlab-services-version-gitlab-com-staging.gs-staging.gitlab.org'
    USAGE_DATA_PATH = 'usage_data'
    ERROR_PATH = 'usage_ping_errors'
    METADATA_PATH = 'usage_ping_metadata'

    SubmissionError = Class.new(StandardError)

    def initialize(skip_db_write: false, payload: nil)
      @skip_db_write = skip_db_write
      @payload = payload
    end

    def execute
      return unless ServicePing::ServicePingSettings.product_intelligence_enabled?

      start = Time.current
      begin
        usage_data = payload || ServicePing::BuildPayload.new.execute
        response = submit_usage_data_payload(usage_data)
      rescue StandardError => e
        return unless Gitlab::CurrentSettings.usage_ping_enabled?

        error_payload = {
          time: Time.current,
          uuid: Gitlab::CurrentSettings.uuid,
          hostname: Gitlab.config.gitlab.host,
          version: Gitlab.version_info.to_s,
          message: "#{e.message.presence || e.class} at #{e.backtrace[0]}",
          elapsed: (Time.current - start).round(1)
        }
        submit_payload({ error: error_payload }, path: ERROR_PATH)

        usage_data = payload || Gitlab::Usage::ServicePingReport.for(output: :all_metrics_values)
        response = submit_usage_data_payload(usage_data)
      end

      version_usage_data_id =
        response.dig('conv_index', 'usage_data_id') || response.dig('dev_ops_score', 'usage_data_id')

      unless version_usage_data_id.is_a?(Integer) && version_usage_data_id > 0
        raise SubmissionError, "Invalid usage_data_id in response: #{version_usage_data_id}"
      end

      unless skip_db_write
        raw_usage_data = save_raw_usage_data(usage_data)
        raw_usage_data.update_version_metadata!(usage_data_id: version_usage_data_id)
        ServicePing::DevopsReport.new(response).execute
      end

      submit_payload({ metadata: { metrics: metrics_collection_time(usage_data) } }, path: METADATA_PATH)
    end

    private

    attr_reader :payload, :skip_db_write

    def metrics_collection_time(payload, parents = [])
      return [] unless payload.is_a?(Hash)

      payload.flat_map do |key, metric_value|
        key_path = parents.dup.append(key)
        if metric_value.respond_to?(:duration)
          { name: key_path.join('.'), time_elapsed: metric_value.duration }
        else
          metrics_collection_time(metric_value, key_path)
        end
      end
    end

    def submit_payload(payload, path: USAGE_DATA_PATH)
      Gitlab::HTTP.post(
        URI.join(base_url, path),
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
      # safe_find_or_create_by! was originally called here.
      # We merely switched to `find_or_create_by!`
      # rubocop: disable CodeReuse/ActiveRecord
      RawUsageData.find_or_create_by(recorded_at: usage_data[:recorded_at]) do |record|
        record.payload = usage_data
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end

    # See https://gitlab.com/gitlab-org/gitlab/-/issues/233615 for details
    def base_url
      Rails.env.production? ? PRODUCTION_BASE_URL : STAGING_BASE_URL
    end
  end
end

ServicePing::SubmitService.prepend_mod
