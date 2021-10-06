# frozen_string_literal: true

module Projects::ClusterAgentsHelper
  def js_cluster_agent_details_data(agent_name, project)
    {
      agent_name: agent_name,
      project_path: project.full_path
    }
  end
end
