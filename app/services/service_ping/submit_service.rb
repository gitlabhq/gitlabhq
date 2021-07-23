# frozen_string_literal: true

module ServicePing
  class SubmitService
    PRODUCTION_URL = 'https://version.gitlab.com/usage_data'
    STAGING_URL = 'https://gitlab-services-version-gitlab-com-staging.gs-staging.gitlab.org/usage_data'

    METRICS = %w[leader_issues instance_issues percentage_issues leader_notes instance_notes
                 percentage_notes leader_milestones instance_milestones percentage_milestones
                 leader_boards instance_boards percentage_boards leader_merge_requests
                 instance_merge_requests percentage_merge_requests leader_ci_pipelines
                 instance_ci_pipelines percentage_ci_pipelines leader_environments instance_environments
                 percentage_environments leader_deployments instance_deployments percentage_deployments
                 leader_projects_prometheus_active instance_projects_prometheus_active
                 percentage_projects_prometheus_active leader_service_desk_issues instance_service_desk_issues
                 percentage_service_desk_issues].freeze

    SubmissionError = Class.new(StandardError)

    def execute
      return unless ServicePing::ServicePingSettings.product_intelligence_enabled?

      begin
        usage_data = BuildPayloadService.new.execute
        raw_usage_data, response = submit_usage_data_payload(usage_data)
      rescue StandardError
        return unless Gitlab::CurrentSettings.usage_ping_enabled?

        usage_data = Gitlab::UsageData.data(force_refresh: true)
        raw_usage_data, response = submit_usage_data_payload(usage_data)
      end

      version_usage_data_id = response.dig('conv_index', 'usage_data_id') || response.dig('dev_ops_score', 'usage_data_id')

      unless version_usage_data_id.is_a?(Integer) && version_usage_data_id > 0
        raise SubmissionError, "Invalid usage_data_id in response: #{version_usage_data_id}"
      end

      raw_usage_data.update_version_metadata!(usage_data_id: version_usage_data_id)

      store_metrics(response)
    end

    private

    def submit_payload(usage_data)
      Gitlab::HTTP.post(
        url,
        body: usage_data.to_json,
        allow_local_requests: true,
        headers: { 'Content-type' => 'application/json' }
      )
    end

    def submit_usage_data_payload(usage_data)
      raise SubmissionError, 'Usage data is blank' if usage_data.blank?

      raw_usage_data = save_raw_usage_data(usage_data)

      response = submit_payload(usage_data)

      raise SubmissionError, "Unsuccessful response code: #{response.code}" unless response.success?

      [raw_usage_data, response]
    end

    def save_raw_usage_data(usage_data)
      RawUsageData.safe_find_or_create_by(recorded_at: usage_data[:recorded_at]) do |record|
        record.payload = usage_data
      end
    end

    def store_metrics(response)
      metrics = response['conv_index'] || response['dev_ops_score'] # leaving dev_ops_score here, as the response data comes from the gitlab-version-com

      return unless metrics.present?

      DevOpsReport::Metric.create!(
        metrics.slice(*METRICS)
      )
    end

    # See https://gitlab.com/gitlab-org/gitlab/-/issues/233615 for details
    def url
      if Rails.env.production?
        PRODUCTION_URL
      else
        STAGING_URL
      end
    end
  end
end

ServicePing::SubmitService.prepend_mod
