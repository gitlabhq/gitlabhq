# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeleteOrphanedSbomOccurrences < BatchedMigrationJob
      operation_name :delete_orphaned_sbom_occurrences
      feature_category :dependency_management

      class Project < ::ApplicationRecord
        self.table_name = 'projects'
      end

      def perform
        each_sub_batch do |sub_batch|
          project_ids = sub_batch.distinct.pluck(:project_id)

          non_existent_project_ids = non_existent_project_ids(project_ids)

          next if non_existent_project_ids.blank?

          sub_batch
            .where(project_id: non_existent_project_ids)
            .delete_all
        end
      end

      def non_existent_project_ids(project_ids)
        existing_ids = Project.id_in(project_ids).pluck(:id)

        project_ids - existing_ids
      end
    end
  end
end
