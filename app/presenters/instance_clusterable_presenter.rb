# frozen_string_literal: true

class InstanceClusterablePresenter < ClusterablePresenter
  extend ::Gitlab::Utils::Override
  include ActionView::Helpers::UrlHelper

  def self.fabricate(clusterable, **attributes)
    attributes_with_presenter_class = attributes.merge(presenter_class: InstanceClusterablePresenter)

    Gitlab::View::Presenter::Factory
      .new(clusterable, attributes_with_presenter_class)
      .fabricate!
  end

  override :index_path
  def index_path
    admin_clusters_path
  end

  override :new_path
  def new_path(options = {})
    new_admin_cluster_path(options)
  end

  override :cluster_status_cluster_path
  def cluster_status_cluster_path(cluster, params = {})
    cluster_status_admin_cluster_path(cluster, params)
  end

  override :install_applications_cluster_path
  def install_applications_cluster_path(cluster, application)
    install_applications_admin_cluster_path(cluster, application)
  end

  override :update_applications_cluster_path
  def update_applications_cluster_path(cluster, application)
    update_applications_admin_cluster_path(cluster, application)
  end

  override :clear_cluster_cache_path
  def clear_cluster_cache_path(cluster)
    clear_cache_admin_cluster_path(cluster)
  end

  override :cluster_path
  def cluster_path(cluster, params = {})
    admin_cluster_path(cluster, params)
  end

  override :create_user_clusters_path
  def create_user_clusters_path
    create_user_admin_clusters_path
  end

  override :create_gcp_clusters_path
  def create_gcp_clusters_path
    create_gcp_admin_clusters_path
  end

  override :create_aws_clusters_path
  def create_aws_clusters_path
    create_aws_admin_clusters_path
  end

  override :authorize_aws_role_path
  def authorize_aws_role_path
    authorize_aws_role_admin_clusters_path
  end

  override :revoke_aws_role_path
  def revoke_aws_role_path
    revoke_aws_role_admin_clusters_path
  end

  override :aws_api_proxy_path
  def aws_api_proxy_path(resource)
    aws_proxy_admin_clusters_path(resource: resource)
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
    link_to(s_('ClusterIntegration|Learn more about instance Kubernetes clusters'), help_page_path('user/instance/clusters/index'), target: '_blank', rel: 'noopener noreferrer')
  end
end

InstanceClusterablePresenter.prepend_if_ee('EE::InstanceClusterablePresenter')
