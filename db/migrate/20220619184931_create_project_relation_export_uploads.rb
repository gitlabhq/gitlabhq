# frozen_string_literal: true

class CreateProjectRelationExportUploads < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  INDEX = 'index_project_relation_export_upload_id'

  def change
    create_table :project_relation_export_uploads do |t|
      t.references :project_relation_export, null: false, foreign_key: { on_delete: :cascade }, index: { name: INDEX }
      t.timestamps_with_timezone null: false
      t.text :export_file, null: false, limit: 255
    end
  end
end
