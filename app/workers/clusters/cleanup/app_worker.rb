# frozen_string_literal: true

module Clusters
  module Cleanup
    class AppWorker
      include ClusterCleanupMethods

      def perform(cluster_id, execution_count = 0)
        Clusters::Cluster.with_persisted_applications.find_by_id(cluster_id).try do |cluster|
          break unless cluster.cleanup_uninstalling_applications?

          break exceeded_execution_limit(cluster) if exceeded_execution_limit?(execution_count)

          ::Clusters::Cleanup::AppService.new(cluster, execution_count).execute
        end
      end
    end
  end
end
