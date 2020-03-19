# frozen_string_literal: true

module Clusters
  module Cleanup
    class ServiceAccountWorker # rubocop:disable Scalability/IdempotentWorker
      include ClusterCleanupMethods

      def perform(cluster_id)
        Clusters::Cluster.find_by_id(cluster_id).try do |cluster|
          break unless cluster.cleanup_removing_service_account?

          Clusters::Cleanup::ServiceAccountService.new(cluster).execute
        end
      end
    end
  end
end
