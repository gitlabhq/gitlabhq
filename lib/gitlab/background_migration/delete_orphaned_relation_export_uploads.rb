# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeleteOrphanedRelationExportUploads < BatchedMigrationJob
      operation_name :delete_orphaned_relation_export_uploads
      feature_category :importers

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .joins('LEFT JOIN project_relation_export_uploads ON project_relation_export_uploads.id = uploads.model_id')
            .where(model_type: 'Projects::ImportExport::RelationExportUpload')
            .where(project_relation_export_uploads: { id: nil })
            .delete_all
        end
      end
    end
  end
end
