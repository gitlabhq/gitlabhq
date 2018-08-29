# frozen_string_literal: true

module Clusters
  module Gcp
    module Kubernetes
      class CreateServiceAccountService
        attr_reader :kubeclient

        def initialize(kubeclient)
          @kubeclient = kubeclient
        end

        def execute
          kubeclient.create_service_account(service_account_resource)
          kubeclient.create_cluster_role_binding(cluster_role_binding_resource)
        end

        private

        def service_account_resource
          Gitlab::Kubernetes::ServiceAccount.new(SERVICE_ACCOUNT_NAME, 'default').generate
        end

        def cluster_role_binding_resource
          subjects = [{ kind: 'ServiceAccount', name: SERVICE_ACCOUNT_NAME, namespace: 'default' }]

          Gitlab::Kubernetes::ClusterRoleBinding.new(
            CLUSTER_ROLE_BINDING_NAME,
            CLUSTER_ROLE_NAME,
            subjects
          ).generate
        end
      end
    end
  end
end
