# frozen_string_literal: true

class WaitForClusterCreationWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include ClusterQueue

  worker_has_external_dependencies!

  def perform(cluster_id)
    Clusters::Cluster.find_by_id(cluster_id).try do |cluster|
      cluster.provider.try do |provider|
        if cluster.gcp?
          Clusters::Gcp::VerifyProvisionStatusService.new.execute(provider)
        elsif cluster.aws?
          Clusters::Aws::VerifyProvisionStatusService.new.execute(provider)
        end
      end
    end
  end
end
