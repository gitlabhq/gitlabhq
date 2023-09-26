# frozen_string_literal: true

module Clusters
  module Cleanup
    class ServiceAccountService < ::Clusters::Cleanup::BaseService
      def execute
        delete_gitlab_service_account

        log_event(:destroying_cluster)

        cluster.destroy!
      end

      private

      def delete_gitlab_service_account
        log_event(:deleting_gitlab_service_account)

        cluster.kubeclient&.delete_service_account(
          ::Clusters::Kubernetes::GITLAB_SERVICE_ACCOUNT_NAME,
          ::Clusters::Kubernetes::GITLAB_SERVICE_ACCOUNT_NAMESPACE
        )
      rescue Kubeclient::ResourceNotFoundError
        # The resources have already been deleted, possibly on a previous attempt that timed out
      rescue Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError
        # User gave an invalid cluster from the start, or deleted the endpoint before this job ran
      rescue Kubeclient::HttpError => e
        # unauthorized, forbidden: GitLab's access has been revoked
        # certificate verify failed: Cluster is probably gone forever
        raise unless /unauthorized|forbidden|certificate verify failed/i.match?(e.message)
      end
    end
  end
end
