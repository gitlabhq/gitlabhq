# frozen_string_literal: true

class GroupClusterablePresenter < ClusterablePresenter
  extend ::Gitlab::Utils::Override
  include ActionView::Helpers::UrlHelper

  override :cluster_status_cluster_path
  def cluster_status_cluster_path(cluster, params = {})
    cluster_status_group_cluster_path(clusterable, cluster, params)
  end

  override :install_applications_cluster_path
  def install_applications_cluster_path(cluster, application)
    install_applications_group_cluster_path(clusterable, cluster, application)
  end

  override :update_applications_cluster_path
  def update_applications_cluster_path(cluster, application)
    update_applications_group_cluster_path(clusterable, cluster, application)
  end

  override :clear_cluster_cache_path
  def clear_cluster_cache_path(cluster)
    clear_cache_group_cluster_path(clusterable, cluster)
  end

  override :cluster_path
  def cluster_path(cluster, params = {})
    group_cluster_path(clusterable, cluster, params)
  end

  override :empty_state_help_text
  def empty_state_help_text
    s_('ClusterIntegration|Adding an integration to your group will share the cluster across all your projects.')
  end

  override :sidebar_text
  def sidebar_text
    s_('ClusterIntegration|Adding a Kubernetes cluster to your group will automatically share the cluster across all your projects. Use review apps, deploy your applications, and easily run your pipelines for all projects using the same cluster.')
  end

  override :learn_more_link
  def learn_more_link
    link_to(s_('ClusterIntegration|Learn more about group Kubernetes clusters'), help_page_path('user/group/clusters/index'), target: '_blank', rel: 'noopener noreferrer')
  end
end

GroupClusterablePresenter.prepend_if_ee('EE::GroupClusterablePresenter')
