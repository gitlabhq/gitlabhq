# frozen_string_literal: true

class ClusterEntity < Grape::Entity
  include RequestAwareEntity

  expose :cluster_type
  expose :enabled
  expose :environment_scope
  expose :id
  expose :namespace_per_environment
  expose :name
  expose :nodes
  expose :provider_type
  expose :status_name, as: :status
  expose :status_reason
  expose :applications, using: ClusterApplicationEntity

  expose :path do |cluster|
    Clusters::ClusterPresenter.new(cluster).show_path # rubocop: disable CodeReuse/Presenter
  end

  expose :gitlab_managed_apps_logs_path do |cluster|
    Clusters::ClusterPresenter.new(cluster, current_user: request.current_user).gitlab_managed_apps_logs_path # rubocop: disable CodeReuse/Presenter
  end

  expose :kubernetes_errors do |cluster|
    ClusterErrorEntity.new(cluster)
  end

  expose :enable_advanced_logs_querying do |cluster|
    cluster.elastic_stack_available?
  end
end
