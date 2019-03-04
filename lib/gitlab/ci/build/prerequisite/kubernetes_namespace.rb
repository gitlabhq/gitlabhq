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
            build.has_deployment? && clusters_missing_namespaces.present?
          end

          def complete!
            return unless unmet?

            clusters_missing_namespaces.each do |cluster|
              create_or_update_namespace(cluster)
            end
          end

          private

          def project
            build.project
          end

          def create_or_update_namespace(cluster)
            kubernetes_namespace = cluster.find_or_initialize_kubernetes_namespace_for_project(project)

            Clusters::Gcp::Kubernetes::CreateOrUpdateNamespaceService.new(
              cluster: cluster,
              kubernetes_namespace: kubernetes_namespace
            ).execute
          end

          def clusters_missing_namespaces
            strong_memoize(:clusters_missing_namespaces) do
              project.all_clusters.missing_kubernetes_namespace(project.kubernetes_namespaces).to_a
            end
          end
        end
      end
    end
  end
end
