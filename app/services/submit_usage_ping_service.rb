class SubmitUsagePingService
  URL = 'https://version.gitlab.com/usage_data'.freeze

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

    response = HTTParty.post(
      URL,
      body: Gitlab::UsageData.to_json(force_refresh: true),
      headers: { 'Content-type' => 'application/json' }
    )

    store_metrics(response)

    true
  rescue HTTParty::Error => e
    Rails.logger.info "Unable to contact GitLab, Inc.: #{e}"

    false
  end

  private

  def store_metrics(response)
    return unless response['conv_index'].present?

    ConversationalDevelopmentIndex::Metric.create!(
      response['conv_index'].slice(*METRICS)
    )
  end
end
