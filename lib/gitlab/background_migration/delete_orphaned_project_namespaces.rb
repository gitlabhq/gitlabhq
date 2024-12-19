# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeleteOrphanedProjectNamespaces < BatchedMigrationJob
      operation_name :delete_orphaned_project_namespaces_records
      feature_category :groups_and_projects

      scope_to ->(relation) { relation.where(type: 'Project') }

      class Project < ::ApplicationRecord
        self.table_name = 'projects'
      end

      class ProjectNamespace < ::ApplicationRecord
        self.table_name = 'namespaces'
        self.inheritance_column = :_type_disabled
      end

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
          .joins("LEFT JOIN namespaces AS parent ON namespaces.parent_id = parent.id")
          .where.not(parent_id: nil)
          .where(parent: { id: nil })
          .pluck(:id).each do |orphaned_namespace_id|
            next if Project.exists?(project_namespace_id: orphaned_namespace_id)

            ProjectNamespace.delete(orphaned_namespace_id)
          end
        end
      end
    end
  end
end
