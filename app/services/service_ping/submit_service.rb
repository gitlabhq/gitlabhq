# frozen_string_literal: true

module ServicePing
  class SubmitService
    PRODUCTION_BASE_URL = 'https://version.gitlab.com'
    STAGING_BASE_URL = 'https://gitlab-org-gitlab-services-version-gitlab-com-staging.version-staging.gitlab.org'
    USAGE_DATA_PATH = 'usage_data'
    ERROR_PATH = 'usage_ping_errors'
    METADATA_PATH = 'usage_ping_metadata'

    SubmissionError = Class.new(StandardError)

    def initialize(payload: nil)
      @payload = payload
    end

    def execute
      return unless ServicePing::ServicePingSettings.enabled_and_consented?

      start_time = Time.current

      begin
        response = submit_usage_data_payload

        raise SubmissionError, "Unsuccessful response code: #{response.code}" unless response.success?

        handle_response(response)
        submit_metadata_payload
      rescue StandardError => e
        submit_error_payload(e, start_time)

        raise
      end
    end

    private

    attr_reader :payload

    def metadata(service_ping_payload)
      {
        metadata: {
          uuid: service_ping_payload[:uuid],
          metrics: metrics_collection_metadata(service_ping_payload)
        }
      }
    end

    def metrics_collection_metadata(payload, parents = [])
      return [] unless payload.is_a?(Hash)

      payload.flat_map do |key, metric_value|
        key_path = parents.dup.append(key)
        if metric_value.respond_to?(:duration)
          { name: key_path.join('.'), time_elapsed: metric_value.duration, error: metric_value.error }.compact
        else
          metrics_collection_metadata(metric_value, key_path)
        end
      end
    end

    def submit_payload(payload, path: USAGE_DATA_PATH)
      Gitlab::HTTP.post(
        URI.join(base_url, path),
        body: Gitlab::Json.dump(payload),
        allow_local_requests: true,
        headers: {
          'Content-type' => 'application/json',
          'Accept' => 'application/json'
        }
      )
    end

    def submit_usage_data_payload
      raise SubmissionError, 'Usage data payload is blank' if payload.blank?

      submit_payload(payload)
    end

    def handle_response(response)
      version_usage_data_id =
        response.dig('conv_index', 'usage_data_id') || response.dig('dev_ops_score', 'usage_data_id')

      unless version_usage_data_id.is_a?(Integer) && version_usage_data_id > 0
        raise SubmissionError, "Invalid usage_data_id in response: #{version_usage_data_id}"
      end

      raw_usage_data = save_raw_usage_data(payload)
      raw_usage_data.update_version_metadata!(usage_data_id: version_usage_data_id)
      ServicePing::DevopsReport.new(response).execute
    end

    def submit_error_payload(error, start_time)
      current_time = Time.current
      error_payload = {
        time: current_time,
        uuid: Gitlab::CurrentSettings.uuid,
        hostname: Gitlab.config.gitlab.host,
        version: Gitlab.version_info.to_s,
        message: "#{error.message.presence || error.class} at #{error.backtrace[0]}",
        elapsed: (current_time - start_time).round(1)
      }

      submit_payload({ error: error_payload }, path: ERROR_PATH)
    end

    def submit_metadata_payload
      submit_payload(metadata(payload), path: METADATA_PATH)
    end

    def save_raw_usage_data(usage_data)
      # safe_find_or_create_by! was originally called here.
      # We merely switched to `find_or_create_by!`
      # rubocop: disable CodeReuse/ActiveRecord
      RawUsageData.find_or_create_by(recorded_at: usage_data[:recorded_at]) do |record|
        record.payload = usage_data
        record.organization_id = Organizations::Organization.first.id
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
