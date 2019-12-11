# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Prerequisite
        class KubernetesNamespace < Base
          def unmet?
            deployment_cluster.present? &&
              deployment_cluster.managed? &&
              (missing_namespace? || need_knative_version_role_binding?)
          end

          def complete!
            return unless unmet?

            create_namespace
          end

          private

          def missing_namespace?
            kubernetes_namespace.nil? || kubernetes_namespace.service_account_token.blank?
          end

          def need_knative_version_role_binding?
            !knative_serving_namespace.nil? && knative_version_role_binding.nil?
          end

          def deployment_cluster
            build.deployment&.cluster
          end

          def environment
            build.deployment.environment
          end

          def knative_serving_namespace
            strong_memoize(:knative_serving_namespace) do
              Clusters::KnativeServingNamespaceFinder.new(
                deployment_cluster
              ).execute
            end
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
            namespace = kubernetes_namespace || build_namespace_record

            return if conflicting_ci_namespace_requested?(namespace)

            Clusters::Kubernetes::CreateOrUpdateNamespaceService.new(
              cluster: deployment_cluster,
              kubernetes_namespace: namespace
            ).execute
          end

          ##
          # A namespace can only be specified via gitlab-ci.yml
          # for unmanaged clusters, as we currently have no way
          # of preventing a job requesting a namespace it
          # shouldn't have access to.
          #
          # To make this clear, we fail the build instead of
          # silently using a namespace other than the one
          # explicitly specified.
          #
          # Support for managed clusters will be added in
          # https://gitlab.com/gitlab-org/gitlab/issues/38054
          def conflicting_ci_namespace_requested?(namespace_record)
            build.expanded_kubernetes_namespace.present? &&
              namespace_record.namespace != build.expanded_kubernetes_namespace
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
