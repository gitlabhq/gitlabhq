# frozen_string_literal: true

class ProjectClusterablePresenter < ClusterablePresenter
  def index_path
    project_clusters_path(clusterable)
  end

  def new_path
    new_project_cluster_path(clusterable)
  end

  def clusterable_params
    { project_id: clusterable.to_param, namespace_id: clusterable.namespace.to_param }
  end
end
