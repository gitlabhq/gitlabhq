# frozen_string_literal: true

class GroupClusterablePresenter < ClusterablePresenter
  extend ::Gitlab::Utils::Override

  presents ::Group

  override :cluster_status_cluster_path
  def cluster_status_cluster_path(cluster, params = {})
    cluster_status_group_cluster_path(clusterable, cluster, params)
  end

  override :clear_cluster_cache_path
  def clear_cluster_cache_path(cluster)
    clear_cache_group_cluster_path(clusterable, cluster)
  end

  override :create_cluster_migration_path
  def create_cluster_migration_path(cluster)
    migrate_group_cluster_path(clusterable, cluster)
  end

  override :update_cluster_migration_path
  def update_cluster_migration_path(cluster)
    update_migration_group_cluster_path(clusterable, cluster)
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
    s_('ClusterIntegration|Connect your group to a Kubernetes cluster with the GitLab agent and share the connection across multiple projects. Use review apps, deploy your applications, and easily run your pipelines for all projects using the same cluster.')
  end

  override :learn_more_link
  def learn_more_link
    ApplicationController.helpers.link_to(s_('ClusterIntegration|Learn more about group Kubernetes clusters'), help_page_path('user/group/clusters/_index.md'), target: '_blank', rel: 'noopener noreferrer')
  end
end

GroupClusterablePresenter.prepend_mod_with('GroupClusterablePresenter')
