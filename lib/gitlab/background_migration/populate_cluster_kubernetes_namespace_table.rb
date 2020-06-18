# frozen_string_literal: true
#
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class PopulateClusterKubernetesNamespaceTable
      include Gitlab::Database::MigrationHelpers

      BATCH_SIZE = 1_000

      module Migratable
        class KubernetesNamespace < ActiveRecord::Base
          self.table_name = 'clusters_kubernetes_namespaces'
        end

        class ClusterProject < ActiveRecord::Base
          include EachBatch

          self.table_name = 'cluster_projects'

          belongs_to :project

          def self.with_no_kubernetes_namespace
            where.not(id: Migratable::KubernetesNamespace.select(:cluster_project_id))
          end

          def namespace
            slug = "#{project.path}-#{project.id}".downcase
            slug.gsub(/[^-a-z0-9]/, '-').gsub(/^-+/, '')
          end

          def service_account
            "#{namespace}-service-account"
          end
        end

        class Project < ActiveRecord::Base
          self.table_name = 'projects'
        end
      end

      def perform
        cluster_projects_with_no_kubernetes_namespace.each_batch(of: BATCH_SIZE) do |cluster_projects_batch, index|
          sql_values = sql_values_for(cluster_projects_batch)

          insert_into_cluster_kubernetes_namespace(sql_values)
        end
      end

      private

      def cluster_projects_with_no_kubernetes_namespace
        Migratable::ClusterProject.with_no_kubernetes_namespace
      end

      def sql_values_for(cluster_projects)
        cluster_projects.map do |cluster_project|
          values_for_cluster_project(cluster_project)
        end
      end

      def values_for_cluster_project(cluster_project)
        {
          cluster_project_id: cluster_project.id,
          cluster_id: cluster_project.cluster_id,
          project_id: cluster_project.project_id,
          namespace: cluster_project.namespace,
          service_account_name: cluster_project.service_account,
          created_at: 'NOW()',
          updated_at: 'NOW()'
        }
      end

      def insert_into_cluster_kubernetes_namespace(rows)
        Gitlab::Database.bulk_insert(Migratable::KubernetesNamespace.table_name, # rubocop:disable Gitlab/BulkInsert
                                     rows,
                                     disable_quote: [:created_at, :updated_at])
      end
    end
  end
end
