# frozen_string_literal: true

class ClusterPlatformConfigureWorker
  include ApplicationWorker
  include ClusterQueue

  def perform(cluster_id)
    Clusters::Cluster.find_by_id(cluster_id).try do |cluster|
      cluster.platform_kubernetes.try do |platform|
        Clusters::Kubernetes::ConfigureService.new(platform).execute
      end
    end
  end
end
