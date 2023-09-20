# frozen_string_literal: true

module Clusters
  module Kubernetes
    class CreateOrUpdateServiceAccountService
      def initialize(kubeclient, service_account_name:, service_account_namespace:, token_name:, rbac:, service_account_namespace_labels: nil, namespace_creator: false, role_binding_name: nil)
        @kubeclient = kubeclient
        @service_account_name = service_account_name
        @service_account_namespace = service_account_namespace
        @service_account_namespace_labels = service_account_namespace_labels
        @token_name = token_name
        @rbac = rbac
        @namespace_creator = namespace_creator
        @role_binding_name = role_binding_name
      end

      def self.gitlab_creator(kubeclient, rbac:)
        self.new(
          kubeclient,
          service_account_name: Clusters::Kubernetes::GITLAB_SERVICE_ACCOUNT_NAME,
          service_account_namespace: Clusters::Kubernetes::GITLAB_SERVICE_ACCOUNT_NAMESPACE,
          token_name: Clusters::Kubernetes::GITLAB_ADMIN_TOKEN_NAME,
          rbac: rbac
        )
      end

      def self.namespace_creator(kubeclient, service_account_name:, service_account_namespace:, service_account_namespace_labels:, rbac:)
        self.new(
          kubeclient,
          service_account_name: service_account_name,
          service_account_namespace: service_account_namespace,
          service_account_namespace_labels: service_account_namespace_labels,
          token_name: "#{service_account_namespace}-token",
          rbac: rbac,
          namespace_creator: true,
          role_binding_name: "gitlab-#{service_account_namespace}"
        )
      end

      def execute
        ensure_project_namespace_exists if namespace_creator

        kubeclient.create_or_update_service_account(service_account_resource)
        kubeclient.create_or_update_secret(service_account_token_resource)

        return unless rbac

        create_role_or_cluster_role_binding

        return unless namespace_creator

        create_or_update_knative_serving_role
        create_or_update_knative_serving_role_binding
        create_or_update_crossplane_database_role
        create_or_update_crossplane_database_role_binding
      end

      private

      attr_reader :kubeclient, :service_account_name, :service_account_namespace, :service_account_namespace_labels, :token_name, :rbac, :namespace_creator, :role_binding_name

      def ensure_project_namespace_exists
        Gitlab::Kubernetes::Namespace.new(
          service_account_namespace,
          kubeclient,
          labels: service_account_namespace_labels
        ).ensure_exists!
      end

      def create_role_or_cluster_role_binding
        if namespace_creator
          begin
            kubeclient.delete_role_binding(role_binding_name, service_account_namespace)
          rescue Kubeclient::ResourceNotFoundError
            # Do nothing as we will create new role binding below
          end

          kubeclient.update_role_binding(role_binding_resource)
        else
          kubeclient.create_or_update_cluster_role_binding(cluster_role_binding_resource)
        end
      end

      def create_or_update_knative_serving_role
        kubeclient.update_role(knative_serving_role_resource)
      end

      def create_or_update_knative_serving_role_binding
        kubeclient.update_role_binding(knative_serving_role_binding_resource)
      end

      def create_or_update_crossplane_database_role
        kubeclient.update_role(crossplane_database_role_resource)
      end

      def create_or_update_crossplane_database_role_binding
        kubeclient.update_role_binding(crossplane_database_role_binding_resource)
      end

      def service_account_resource
        Gitlab::Kubernetes::ServiceAccount.new(
          service_account_name,
          service_account_namespace
        ).generate
      end

      def service_account_token_resource
        Gitlab::Kubernetes::ServiceAccountToken.new(
          token_name,
          service_account_name,
          service_account_namespace
        ).generate
      end

      def cluster_role_binding_resource
        subjects = [{ kind: 'ServiceAccount', name: service_account_name, namespace: service_account_namespace }]

        Gitlab::Kubernetes::ClusterRoleBinding.new(
          Clusters::Kubernetes::GITLAB_CLUSTER_ROLE_BINDING_NAME,
          Clusters::Kubernetes::GITLAB_CLUSTER_ROLE_NAME,
          subjects
        ).generate
      end

      def role_binding_resource
        Gitlab::Kubernetes::RoleBinding.new(
          name: role_binding_name,
          role_name: Clusters::Kubernetes::PROJECT_CLUSTER_ROLE_NAME,
          role_kind: :ClusterRole,
          namespace: service_account_namespace,
          service_account_name: service_account_name
        ).generate
      end

      def knative_serving_role_resource
        Gitlab::Kubernetes::Role.new(
          name: Clusters::Kubernetes::GITLAB_KNATIVE_SERVING_ROLE_NAME,
          namespace: service_account_namespace,
          rules: [{
            apiGroups: %w[serving.knative.dev],
            resources: %w[configurations configurationgenerations routes revisions revisionuids autoscalers services],
            verbs: %w[get list create update delete patch watch]
          }]
        ).generate
      end

      def knative_serving_role_binding_resource
        Gitlab::Kubernetes::RoleBinding.new(
          name: Clusters::Kubernetes::GITLAB_KNATIVE_SERVING_ROLE_BINDING_NAME,
          role_name: Clusters::Kubernetes::GITLAB_KNATIVE_SERVING_ROLE_NAME,
          role_kind: :Role,
          namespace: service_account_namespace,
          service_account_name: service_account_name
        ).generate
      end

      def crossplane_database_role_resource
        Gitlab::Kubernetes::Role.new(
          name: Clusters::Kubernetes::GITLAB_CROSSPLANE_DATABASE_ROLE_NAME,
          namespace: service_account_namespace,
          rules: [{
            apiGroups: %w[database.crossplane.io],
            resources: %w[postgresqlinstances],
            verbs: %w[get list create watch]
          }]
        ).generate
      end

      def crossplane_database_role_binding_resource
        Gitlab::Kubernetes::RoleBinding.new(
          name: Clusters::Kubernetes::GITLAB_CROSSPLANE_DATABASE_ROLE_BINDING_NAME,
          role_name: Clusters::Kubernetes::GITLAB_CROSSPLANE_DATABASE_ROLE_NAME,
          role_kind: :Role,
          namespace: service_account_namespace,
          service_account_name: service_account_name
        ).generate
      end
    end
  end
end
