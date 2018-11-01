# frozen_string_literal: true

class ProjectClusterablePresenter < ClusterablePresenter
  def index_path
    project_clusters_path(clusterable)
  end

  def new_path
    new_project_cluster_path(clusterable)
  end

  def create_user_clusters_path
    create_user_project_clusters_path(clusterable)
  end

  def create_gcp_clusters_path
    create_gcp_project_clusters_path(clusterable)
  end

  def cluster_status_cluster_path(cluster, params = {})
    cluster_status_project_cluster_path(clusterable, cluster, params)
  end

  def install_applications_cluster_path(cluster, application)
    install_applications_project_cluster_path(clusterable, cluster, application)
  end

  def cluster_path(cluster, params = {})
    project_cluster_path(clusterable, cluster, params)
  end

  def clusterable_params
    { project_id: clusterable.to_param, namespace_id: clusterable.namespace.to_param }
  end
end
