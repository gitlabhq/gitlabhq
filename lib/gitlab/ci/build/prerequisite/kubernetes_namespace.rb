# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Prerequisite
        class KubernetesNamespace < Base
          def unmet?
            deployment_cluster.present? &&
              deployment_cluster.managed? &&
              (kubernetes_namespace.new_record? || kubernetes_namespace.service_account_token.blank?)
          end

          def complete!
            return unless unmet?

            create_or_update_namespace
          end

          private

          def deployment_cluster
            build.deployment&.deployment_platform_cluster
          end

          def kubernetes_namespace
            strong_memoize(:kubernetes_namespace) do
              deployment_cluster.find_or_initialize_kubernetes_namespace_for_project(build.project)
            end
          end

          def create_or_update_namespace
            Clusters::Gcp::Kubernetes::CreateOrUpdateNamespaceService.new(
              cluster: deployment_cluster,
              kubernetes_namespace: kubernetes_namespace
            ).execute
          end
        end
      end
    end
  end
end
