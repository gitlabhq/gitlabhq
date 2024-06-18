# frozen_string_literal: true

class DeploymentClusterEntity < Grape::Entity
  include RequestAwareEntity

  # Until data is copied over from deployments.cluster_id, this entity must represent Deployment instead of DeploymentCluster
  # https://gitlab.com/gitlab-org/gitlab/issues/202628

  expose :name do |deployment|
    deployment.cluster.name
  end

  expose :path, if: ->(deployment) { can?(request.current_user, :read_cluster, deployment.cluster) } do |deployment|
    deployment.cluster.present(current_user: request.current_user).show_path
  end

  expose :kubernetes_namespace, if: ->(deployment) { can?(request.current_user, :read_cluster, deployment.cluster) } do |deployment|
    deployment.kubernetes_namespace
  end
end
