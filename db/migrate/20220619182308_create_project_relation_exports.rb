# frozen_string_literal: true

class CreateProjectRelationExports < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  UNIQUE_INDEX_NAME = 'index_project_export_job_relation'

  def change
    create_table :project_relation_exports do |t|
      t.references :project_export_job, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.integer :status, limit: 2, null: false, default: 0
      t.text :relation, null: false, limit: 255
      t.text :jid, limit: 255
      t.text :export_error, limit: 300

      t.index [:project_export_job_id, :relation], unique: true, name: UNIQUE_INDEX_NAME
    end
  end
end
