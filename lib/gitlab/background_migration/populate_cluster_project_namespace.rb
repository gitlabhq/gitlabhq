# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class PopulateClusterProjectNamespace
      module Migratable
        class ClusterProject < ActiveRecord::Base
          self.table_name = 'cluster_projects'

          belongs_to :project

          def default_namespace
            slug = "#{project.path}-#{project.id}".downcase
            slug.gsub(/[^-a-z0-9]/, '-').gsub(/^-+/, '')
          end
        end

        class Project < ActiveRecord::Base
          self.table_name = 'projects'
        end
      end

      def perform(start_id, stop_id)
        cluster_project_attributes = {}

        cluster_project_collection(start_id, stop_id).each do |cluster_project|
          cluster_project_attributes[cluster_project.id] = { namespace: cluster_project.default_namespace }
        end

        Migratable::ClusterProject.update(cluster_project_attributes.keys, cluster_project_attributes.values)
      end

      private

      def cluster_project_collection(start_id, stop_id)
        Migratable::ClusterProject.where(id: (start_id..stop_id))
      end
    end
  end
end
