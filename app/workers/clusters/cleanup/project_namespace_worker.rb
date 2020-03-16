# frozen_string_literal: true

module Clusters
  module Cleanup
    class ProjectNamespaceWorker # rubocop:disable Scalability/IdempotentWorker
      include ClusterCleanupMethods

      def perform(cluster_id, execution_count = 0)
        Clusters::Cluster.find_by_id(cluster_id).try do |cluster|
          break unless cluster.cleanup_removing_project_namespaces?

          break exceeded_execution_limit(cluster) if exceeded_execution_limit?(execution_count)

          Clusters::Cleanup::ProjectNamespaceService.new(cluster, execution_count).execute
        end
      end
    end
  end
end
