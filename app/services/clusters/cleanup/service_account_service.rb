# frozen_string_literal: true

module Clusters
  module Cleanup
    class ServiceAccountService < BaseService
      def execute
        delete_gitlab_service_account

        log_event(:destroying_cluster)

        cluster.destroy!
      end

      private

      def delete_gitlab_service_account
        log_event(:deleting_gitlab_service_account)

        cluster.kubeclient.delete_service_account(
          ::Clusters::Kubernetes::GITLAB_SERVICE_ACCOUNT_NAME,
          ::Clusters::Kubernetes::GITLAB_SERVICE_ACCOUNT_NAMESPACE
        )
      rescue Kubeclient::ResourceNotFoundError
      end
    end
  end
end
