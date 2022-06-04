# frozen_string_literal: true

module Projects::ClusterAgentsHelper
  def js_cluster_agent_details_data(agent_name, project)
    {
      activity_empty_state_image: image_path('illustrations/empty-state/empty-state-agents.svg'),
      agent_name: agent_name,
      can_admin_vulnerability: can?(current_user, :admin_vulnerability, project).to_s,
      empty_state_svg_path: image_path('illustrations/operations-dashboard_empty.svg'),
      project_path: project.full_path,
      kas_address: Gitlab::Kas.external_url,
      kas_version: Gitlab::Kas.version_info,
      can_admin_cluster: can?(current_user, :admin_cluster, project).to_s
    }
  end
end
