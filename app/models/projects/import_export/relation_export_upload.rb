# frozen_string_literal: true

module Projects
  module ImportExport
    class RelationExportUpload < ApplicationRecord
      include WithUploads

      self.table_name = 'project_relation_export_uploads'

      belongs_to :relation_export,
        class_name: 'Projects::ImportExport::RelationExport',
        foreign_key: :project_relation_export_id,
        inverse_of: :upload

      scope :for_project_export_jobs, ->(export_job_ids) do
        joins(:relation_export).where(
          relation_export: { project_export_job_id: export_job_ids }
        )
      end

      mount_uploader :export_file, ImportExportUploader
    end
  end
end
