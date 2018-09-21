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
          kubeclient.create_service_account(service_account_resource)
          kubeclient.create_secret(service_account_token_resource)
          kubeclient.create_role_binding(role_binding_resource) if rbac
        end

        private

        def service_account_resource
          Gitlab::Kubernetes::ServiceAccount.new(name, namespace).generate
        end

        def service_account_token_resource
          Gitlab::Kubernetes::ServiceAccountToken.new(
            service_account_token_name, name, namespace).generate
        end

        def service_account_token_name
          SERVICE_ACCOUNT_TOKEN_NAME
        end

        def edit_role_name
          EDIT_ROLE_NAME
        end

        def role_binding_resource
          Gitlab::Kubernetes::RoleBinding.new(
            role_name: edit_role_name,
            namespace: namespace,
            service_account_name: name
          ).generate
        end
      end
    end
  end
end
