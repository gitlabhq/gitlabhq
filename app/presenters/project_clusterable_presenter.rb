# frozen_string_literal: true

class ProjectClusterablePresenter < ClusterablePresenter
  extend ::Gitlab::Utils::Override
  include ActionView::Helpers::UrlHelper

  override :cluster_status_cluster_path
  def cluster_status_cluster_path(cluster, params = {})
    cluster_status_project_cluster_path(clusterable, cluster, params)
  end

  override :install_applications_cluster_path
  def install_applications_cluster_path(cluster, application)
    install_applications_project_cluster_path(clusterable, cluster, application)
  end

  override :cluster_path
  def cluster_path(cluster, params = {})
    project_cluster_path(clusterable, cluster, params)
  end

  override :learn_more_link
  def learn_more_link
    link_to(s_('ClusterIntegration|Learn more about Kubernetes'), help_page_path('user/project/clusters/index'), target: '_blank', rel: 'noopener noreferrer')
  end
end
