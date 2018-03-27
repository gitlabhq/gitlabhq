class ClusterProvisionWorker
  include ApplicationWorker
  include ClusterQueue

  def perform(cluster_id)
    Clusters::Cluster.find_by_id(cluster_id).try do |cluster|
      cluster.provider.try do |provider|
        Clusters::Gcp::ProvisionService.new.execute(provider) if cluster.gcp?
      end
    end
  end
end
