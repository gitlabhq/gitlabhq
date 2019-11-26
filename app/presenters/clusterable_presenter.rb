# frozen_string_literal: true

class ClusterablePresenter < Gitlab::View::Presenter::Delegated
  presents :clusterable

  def self.fabricate(clusterable, **attributes)
    presenter_class = "#{clusterable.class.name}ClusterablePresenter".constantize
    attributes_with_presenter_class = attributes.merge(presenter_class: presenter_class)

    Gitlab::View::Presenter::Factory
      .new(clusterable, attributes_with_presenter_class)
      .fabricate!
  end

  def can_add_cluster?
    can?(current_user, :add_cluster, clusterable) &&
      (has_no_clusters? || multiple_clusters_available?)
  end

  def can_create_cluster?
    can?(current_user, :create_cluster, clusterable)
  end

  def index_path
    polymorphic_path([clusterable, :clusters])
  end

  def new_path(options = {})
    new_polymorphic_path([clusterable, :cluster], options)
  end

  def aws_api_proxy_path(resource)
    polymorphic_path([clusterable, :clusters], action: :aws_proxy, resource: resource)
  end

  def authorize_aws_role_path
    polymorphic_path([clusterable, :clusters], action: :authorize_aws_role)
  end

  def revoke_aws_role_path
    polymorphic_path([clusterable, :clusters], action: :revoke_aws_role)
  end

  def create_user_clusters_path
    polymorphic_path([clusterable, :clusters], action: :create_user)
  end

  def create_gcp_clusters_path
    polymorphic_path([clusterable, :clusters], action: :create_gcp)
  end

  def create_aws_clusters_path
    polymorphic_path([clusterable, :clusters], action: :create_aws)
  end

  def cluster_status_cluster_path(cluster, params = {})
    raise NotImplementedError
  end

  def install_applications_cluster_path(cluster, application)
    raise NotImplementedError
  end

  def update_applications_cluster_path(cluster, application)
    raise NotImplementedError
  end

  def clear_cluster_cache_path(cluster)
    raise NotImplementedError
  end

  def cluster_path(cluster, params = {})
    raise NotImplementedError
  end

  # Will be overidden in EE
  def environments_cluster_path(cluster)
    nil
  end

  def empty_state_help_text
    nil
  end

  def sidebar_text
    raise NotImplementedError
  end

  def learn_more_link
    raise NotImplementedError
  end

  private

  # Overridden on EE module
  def multiple_clusters_available?
    false
  end

  def has_no_clusters?
    clusterable.clusters.empty?
  end
end

ClusterablePresenter.prepend_if_ee('EE::ClusterablePresenter')
