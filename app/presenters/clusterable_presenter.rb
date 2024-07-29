# frozen_string_literal: true

class ClusterablePresenter < Gitlab::View::Presenter::Delegated
  presents ::Project, ::Group, ::Clusters::Instance, as: :clusterable

  def self.fabricate(clusterable, **attributes)
    presenter_class = "#{clusterable.class.name}ClusterablePresenter".constantize
    attributes_with_presenter_class = attributes.merge(presenter_class: presenter_class)

    Gitlab::View::Presenter::Factory
      .new(clusterable, **attributes_with_presenter_class)
      .fabricate!
  end

  def can_add_cluster?
    can?(current_user, :add_cluster, clusterable)
  end

  def can_admin_cluster?
    can?(current_user, :admin_cluster, clusterable)
  end

  def can_create_cluster?
    can?(current_user, :create_cluster, clusterable)
  end

  def index_path(options = {})
    polymorphic_path([clusterable, :clusters], options)
  end

  def connect_path
    polymorphic_path([clusterable, :clusters], action: :connect)
  end

  def new_cluster_docs_path
    polymorphic_path([clusterable, :clusters], action: :new_cluster_docs)
  end

  def create_user_clusters_path
    polymorphic_path([clusterable, :clusters], action: :create_user)
  end

  def cluster_status_cluster_path(cluster, params = {})
    raise NotImplementedError
  end

  def clear_cluster_cache_path(cluster)
    raise NotImplementedError
  end

  def cluster_path(cluster, params = {})
    raise NotImplementedError
  end

  # Will be overridden in EE
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
end

ClusterablePresenter.prepend_mod_with('ClusterablePresenter')
