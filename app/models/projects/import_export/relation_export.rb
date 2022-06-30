# frozen_string_literal: true

module Projects
  module ImportExport
    class RelationExport < ApplicationRecord
      self.table_name = 'project_relation_exports'

      belongs_to :project_export_job

      has_one :upload,
        class_name: 'Projects::ImportExport::RelationExportUpload',
        foreign_key: :project_relation_export_id,
        inverse_of: :relation_export

      validates :export_error, length: { maximum: 300 }
      validates :jid, length: { maximum: 255 }
      validates :project_export_job, presence: true
      validates :relation, presence: true, length: { maximum: 255 }, uniqueness: { scope: :project_export_job_id }
      validates :status, numericality: { only_integer: true }, presence: true
    end
  end
end
