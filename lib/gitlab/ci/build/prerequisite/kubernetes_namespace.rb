# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Prerequisite
        class KubernetesNamespace < Base
          ##
          # Cluster settings may have changed since the last deploy,
          # so we must always ensure the namespace is up to date.
          #
          def unmet?
            deployment_cluster.present?
          end

          def complete!
            return unless unmet?

            create_or_update_namespace
          end

          private

          def deployment_cluster
            build.deployment&.cluster
          end

          def create_or_update_namespace
            kubernetes_namespace = deployment_cluster.find_or_initialize_kubernetes_namespace_for_project(build.project)

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
