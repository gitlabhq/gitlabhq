# frozen_string_literal: true

class SubmitUsagePingService
  URL = 'https://version.gitlab.com/usage_data'

  METRICS = %w[leader_issues instance_issues percentage_issues leader_notes instance_notes
               percentage_notes leader_milestones instance_milestones percentage_milestones
               leader_boards instance_boards percentage_boards leader_merge_requests
               instance_merge_requests percentage_merge_requests leader_ci_pipelines
               instance_ci_pipelines percentage_ci_pipelines leader_environments instance_environments
               percentage_environments leader_deployments instance_deployments percentage_deployments
               leader_projects_prometheus_active instance_projects_prometheus_active
               percentage_projects_prometheus_active leader_service_desk_issues instance_service_desk_issues
               percentage_service_desk_issues].freeze

  def execute
    return false unless Gitlab::CurrentSettings.usage_ping_enabled?
    return false if User.single_user&.requires_usage_stats_consent?

    response = Gitlab::HTTP.post(
      URL,
      body: Gitlab::UsageData.to_json(force_refresh: true),
      allow_local_requests: true,
      headers: { 'Content-type' => 'application/json' }
    )

    store_metrics(response)

    true
  rescue Gitlab::HTTP::Error => e
    Gitlab::AppLogger.info("Unable to contact GitLab, Inc.: #{e}")

    false
  end

  private

  def store_metrics(response)
    metrics = response['conv_index'] || response['dev_ops_score']

    return unless metrics.present?

    DevOpsScore::Metric.create!(
      metrics.slice(*METRICS)
    )
  end
end
