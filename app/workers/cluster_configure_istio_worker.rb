# frozen_string_literal: true

class ClusterConfigureIstioWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include ClusterQueue

  worker_has_external_dependencies!

  def perform(cluster_id)
    Clusters::Cluster.find_by_id(cluster_id).try do |cluster|
      Clusters::Kubernetes::ConfigureIstioIngressService.new(cluster: cluster).execute
    end
  end
end
