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

      # This causes CarrierWave v1 and v3 (but not v2) to upload the file to
      # object storage *after* the database entry has been committed to the
      # database. This avoids idling in a transaction. Similar to `ImportExportUpload`.
      if Gitlab::Utils.to_boolean(ENV.fetch('ENABLE_STORE_EXPORT_FILE_AFTER_COMMIT', true))
        skip_callback :save, :after, :store_export_file!
        set_callback :commit, :after, :store_export_file!
      end

      def uploads_sharding_key
        { project_id: relation_export&.project_id }
      end
    end
  end
end
