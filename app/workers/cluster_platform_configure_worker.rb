# frozen_string_literal: true

class ClusterPlatformConfigureWorker
  include ApplicationWorker
  include ClusterQueue

  def perform(cluster_id)
    Clusters::Cluster.find_by_id(cluster_id).try do |cluster|
      next unless cluster.cluster_project

      kubernetes_namespace = cluster.find_or_initialize_kubernetes_namespace(cluster.cluster_project)

      Clusters::Gcp::Kubernetes::CreateOrUpdateNamespaceService.new(
        cluster: cluster,
        kubernetes_namespace: kubernetes_namespace
      ).execute
    end

  rescue ::Kubeclient::HttpError => err
    Rails.logger.error "Failed to create/update Kubernetes Namespace. id: #{kubernetes_namespace.id} message: #{err.message}"
  end
end
