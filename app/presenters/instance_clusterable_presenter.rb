# frozen_string_literal: true

class InstanceClusterablePresenter < ClusterablePresenter
  extend ::Gitlab::Utils::Override

  presents ::Clusters::Instance

  def self.fabricate(clusterable, **attributes)
    attributes_with_presenter_class = attributes.merge(presenter_class: InstanceClusterablePresenter)

    Gitlab::View::Presenter::Factory
      .new(clusterable, **attributes_with_presenter_class)
      .fabricate!
  end

  override :index_path
  def index_path(options = {})
    admin_clusters_path(options)
  end

  override :cluster_status_cluster_path
  def cluster_status_cluster_path(cluster, params = {})
    cluster_status_admin_cluster_path(cluster, params)
  end

  override :clear_cluster_cache_path
  def clear_cluster_cache_path(cluster)
    clear_cache_admin_cluster_path(cluster)
  end

  override :cluster_path
  def cluster_path(cluster, params = {})
    admin_cluster_path(cluster, params)
  end

  override :connect_path
  def connect_path
    connect_admin_clusters_path
  end

  override :new_cluster_docs_path
  def new_cluster_docs_path
    nil
  end

  override :create_user_clusters_path
  def create_user_clusters_path
    create_user_admin_clusters_path
  end

  override :empty_state_help_text
  def empty_state_help_text
    s_('ClusterIntegration|Adding an integration will share the cluster across all projects.')
  end

  override :sidebar_text
  def sidebar_text
    s_('ClusterIntegration|Adding a Kubernetes cluster will automatically share the cluster across all projects. Use review apps, deploy your applications, and easily run your pipelines for all projects using the same cluster.')
  end

  override :learn_more_link
  def learn_more_link
    ApplicationController.helpers.link_to(s_('ClusterIntegration|Learn more about instance Kubernetes clusters'), help_page_path('user/instance/clusters/_index.md'), target: '_blank', rel: 'noopener noreferrer')
  end
end

InstanceClusterablePresenter.prepend_mod_with('InstanceClusterablePresenter')
