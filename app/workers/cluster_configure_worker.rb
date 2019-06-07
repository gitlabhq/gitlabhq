# frozen_string_literal: true

class ClusterConfigureWorker
  include ApplicationWorker
  include ClusterQueue

  def perform(cluster_id)
    Clusters::Cluster.managed.find_by_id(cluster_id).try do |cluster|
      if cluster.project_type?
        Clusters::RefreshService.create_or_update_namespaces_for_cluster(cluster)
      end
    end
  end
end
