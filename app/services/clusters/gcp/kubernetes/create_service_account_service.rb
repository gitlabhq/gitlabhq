# frozen_string_literal: true

module Clusters
  module Gcp
    module Kubernetes
      class CreateServiceAccountService
        attr_reader :kubeclient, :name, :namespace, :rbac

        def initialize(kubeclient, name:, namespace:, rbac:)
          @kubeclient = kubeclient
          @name = name
          @namespace = namespace
          @rbac = rbac
        end

        def execute
          ensure_namespace_exists

          kubeclient.create_service_account(service_account_resource)
          kubeclient.create_secret(service_account_token_resource)

          create_cluster_or_role_binding if rbac
        end

        private

        def ensure_namespace_exists
          Gitlab::Kubernetes::Namespace.new(namespace, kubeclient).ensure_exists!
        end

        def service_account_resource
          Gitlab::Kubernetes::ServiceAccount.new(name, namespace).generate
        end

        def service_account_token_resource
          Gitlab::Kubernetes::ServiceAccountToken.new(
            token_name, name, namespace).generate
        end

        def token_name
          if default_namespace?
            SERVICE_ACCOUNT_TOKEN_NAME
          else
            "#{namespace}-token"
          end
        end

        def create_cluster_or_role_binding
          if default_namespace?
            kubeclient.create_cluster_role_binding(cluster_role_binding_resource)
          else
            kubeclient.create_role_binding(role_binding_resource)
          end
        end

        def cluster_role_binding_resource
          subjects = [{ kind: 'ServiceAccount', name: name, namespace: namespace }]

          Gitlab::Kubernetes::ClusterRoleBinding.new(
            CLUSTER_ROLE_BINDING_NAME,
            CLUSTER_ROLE_NAME,
            subjects
          ).generate
        end

        def role_binding_resource
          Gitlab::Kubernetes::RoleBinding.new(
            role_name: 'edit',
            namespace: namespace,
            service_account_name: name
          ).generate
        end

        def default_namespace?
          namespace == SERVICE_ACCOUNT_NAMESPACE
        end
      end
    end
  end
end
