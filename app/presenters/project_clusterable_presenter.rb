# frozen_string_literal: true

class ProjectClusterablePresenter < ClusterablePresenter
  extend ::Gitlab::Utils::Override

  presents ::Project

  override :cluster_status_cluster_path
  def cluster_status_cluster_path(cluster, params = {})
    cluster_status_project_cluster_path(clusterable, cluster, params)
  end

  override :clear_cluster_cache_path
  def clear_cluster_cache_path(cluster)
    clear_cache_project_cluster_path(clusterable, cluster)
  end

  override :cluster_path
  def cluster_path(cluster, params = {})
    project_cluster_path(clusterable, cluster, params)
  end

  override :sidebar_text
  def sidebar_text
    s_('ClusterIntegration|Use GitLab to deploy to your cluster, run jobs, use review apps, and more.')
  end

  override :learn_more_link
  def learn_more_link
    ApplicationController.helpers.link_to(s_('ClusterIntegration|Learn more about Kubernetes.'), help_page_path('user/project/clusters/_index.md'), target: '_blank', rel: 'noopener noreferrer')
  end
end

ProjectClusterablePresenter.prepend_mod_with('ProjectClusterablePresenter')
