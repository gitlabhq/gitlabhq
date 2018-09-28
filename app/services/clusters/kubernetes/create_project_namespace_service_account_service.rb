# frozen_string_literal: true

module Clusters
  module Kubernetes
    class CreateProjectNamespaceServiceAccountService
      attr_reader :kubeclient, :namespace, :rbac

      def initialize(kubeclient, namespace, rbac: true)
        @kubeclient = kubeclient
        @namespace = namespace
        @rbac = rbac
      end

      def execute
        kubeclient.create_service_account(service_account_resource)
        kubeclient.create_secret(service_account_token_resource)
        kubeclient.create_role_binding(role_binding_resource) if rbac?
      end

      private

      def service_account_name
        'gitlab-deploy'
      end

      def cluster_role_name
        'edit'
      end

      def service_account_resource
        Gitlab::Kubernetes::ServiceAccount.new(service_account_name, namespace).generate
      end

      def service_account_token_resource
        Gitlab::Kubernetes::ServiceAccountToken.new(
          service_account_token_name, service_account_name, namespace).generate
      end

      def role_binding_resource
        Gitlab::Kubernetes::RoleBinding.new(
          role_name: cluster_role_name,
          namespace: namespace,
          service_account_name: service_account_name
        ).generate
      end
    end
  end
end
