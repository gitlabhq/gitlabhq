# frozen_string_literal: true
#
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class PopulateClusterKubernetesNamespace
      module Migratable
        class ClusterKubernetesNamespace < ActiveRecord::Base
          self.table_name = 'clusters_kubernetes_namespaces'
        end

        class ClusterProject < ActiveRecord::Base
          self.table_name = 'cluster_projects'

          belongs_to :project
          belongs_to :cluster

          def self.with_no_kubernetes_namespace
            where.not(id: Migratable::ClusterKubernetesNamespace.select(:cluster_project_id))
          end

          def default_namespace
            slug = "#{project.path}-#{project.id}".downcase
            slug.gsub(/[^-a-z0-9]/, '-').gsub(/^-+/, '')
          end

          def default_service_account
            "#{default_namespace}-service-account"
          end
        end

        class Project < ActiveRecord::Base
          self.table_name = 'projects'
        end

        class Cluster < ActiveRecord::Base
          self.table_name = 'clusters'

          has_one :platform_kubernetes

          def rbac?
            platform_kubernetes.rbac?
          end
        end

        class PlatformKubernetes < ActiveRecord::Base
          self.table_name = 'cluster_platforms_kubernetes'

          belongs_to :cluster

          def rbac?
            authorization_type == :rbac
          end
        end
      end

      def perform(start_id, stop_id)
        cluster_kubernetes_namespace_attributes = []

        cluster_project_collection(start_id, stop_id).each do |cluster_project|
          attributes = {
            cluster_project_id: cluster_project.id,
            namespace: cluster_project.default_namespace,
            service_account_name: cluster_project.default_service_account
          }

          cluster_kubernetes_namespace_attributes << attributes
        end

        Migratable::ClusterKubernetesNamespace.create(cluster_kubernetes_namespace_attributes)
      end

      private

      def cluster_project_collection(start_id, stop_id)
        Migratable::ClusterProject.where(id: (start_id..stop_id)).with_no_kubernetes_namespace
      end
    end
  end
end
