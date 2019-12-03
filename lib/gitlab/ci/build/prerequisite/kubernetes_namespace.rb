# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Prerequisite
        class KubernetesNamespace < Base
          def unmet?
            deployment_cluster.present? &&
              deployment_cluster.managed? &&
              (missing_namespace? || missing_knative_version_role_binding?)
          end

          def complete!
            return unless unmet?

            create_namespace
          end

          private

          def missing_namespace?
            kubernetes_namespace.nil? || kubernetes_namespace.service_account_token.blank?
          end

          def missing_knative_version_role_binding?
            knative_version_role_binding.nil?
          end

          def deployment_cluster
            build.deployment&.cluster
          end

          def environment
            build.deployment.environment
          end

          def knative_version_role_binding
            strong_memoize(:knative_version_role_binding) do
              Clusters::KnativeVersionRoleBindingFinder.new(
                deployment_cluster
              ).execute
            end
          end

          def kubernetes_namespace
            strong_memoize(:kubernetes_namespace) do
              Clusters::KubernetesNamespaceFinder.new(
                deployment_cluster,
                project: environment.project,
                environment_name: environment.name,
                allow_blank_token: true
              ).execute
            end
          end

          def create_namespace
            Clusters::Kubernetes::CreateOrUpdateNamespaceService.new(
              cluster: deployment_cluster,
              kubernetes_namespace: kubernetes_namespace || build_namespace_record
            ).execute
          end

          def build_namespace_record
            Clusters::BuildKubernetesNamespaceService.new(
              deployment_cluster,
              environment: environment
            ).execute
          end
        end
      end
    end
  end
end
