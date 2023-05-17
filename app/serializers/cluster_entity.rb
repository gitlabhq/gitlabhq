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

  expose :path do |cluster|
    Clusters::ClusterPresenter.new(cluster).show_path # rubocop: disable CodeReuse/Presenter
  end

  expose :kubernetes_errors do |cluster|
    Clusters::KubernetesErrorEntity.new(cluster)
  end
end
