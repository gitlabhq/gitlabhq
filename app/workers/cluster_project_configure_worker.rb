# frozen_string_literal: true

class ClusterProjectConfigureWorker
  include ApplicationWorker
  include ClusterQueue

  def perform(project_id)
    return if Feature.enabled?(:ci_preparing_state, default_enabled: true)

    project = Project.find(project_id)

    ::Clusters::RefreshService.create_or_update_namespaces_for_project(project)
  end
end
