# frozen_string_literal: true

module Clusters
  module Cleanup
    class ProjectNamespaceService < ::Clusters::Cleanup::BaseService
      KUBERNETES_NAMESPACE_BATCH_SIZE = 100

      def execute
        delete_project_namespaces_in_batches

        # Keep calling the worker untill all namespaces are deleted
        if cluster.kubernetes_namespaces.exists?
          return schedule_next_execution(Clusters::Cleanup::ProjectNamespaceWorker)
        end

        cluster.continue_cleanup!
      end

      private

      def delete_project_namespaces_in_batches
        kubernetes_namespaces_batch = cluster.kubernetes_namespaces.first(KUBERNETES_NAMESPACE_BATCH_SIZE)

        kubernetes_namespaces_batch.each do |kubernetes_namespace|
          log_event(:deleting_project_namespace, namespace: kubernetes_namespace.namespace)

          begin
            kubeclient_delete_namespace(kubernetes_namespace)
          rescue Kubeclient::HttpError => e
            # unauthorized, forbidden: GitLab's access has been revoked
            # certificate verify failed: Cluster is probably gone forever
            raise unless /unauthorized|forbidden|certificate verify failed/i.match?(e.message)
          end

          kubernetes_namespace.destroy!
        end
      end

      def kubeclient_delete_namespace(kubernetes_namespace)
        cluster.kubeclient&.delete_namespace(kubernetes_namespace.namespace)
      rescue Kubeclient::ResourceNotFoundError
        # The resources have already been deleted, possibly on a previous attempt that timed out
      rescue Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError
        # User gave an invalid cluster from the start, or deleted the endpoint before this job ran
      end
    end
  end
end
