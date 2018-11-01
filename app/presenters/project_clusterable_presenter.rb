# frozen_string_literal: true

class ProjectClusterablePresenter < ClusterablePresenter
  def cluster_status_cluster_path(cluster, params = {})
    cluster_status_project_cluster_path(clusterable, cluster, params)
  end

  def install_applications_cluster_path(cluster, application)
    install_applications_project_cluster_path(clusterable, cluster, application)
  end

  def cluster_path(cluster, params = {})
    project_cluster_path(clusterable, cluster, params)
  end
end
