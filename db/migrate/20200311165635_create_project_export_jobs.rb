# frozen_string_literal: true

class CreateProjectExportJobs < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :project_export_jobs do |t|
      t.references :project, index: false, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.integer :status, limit: 2, null: false, default: 0
      t.string :jid, limit: 100, null: false, unique: true

      t.index [:project_id, :jid]
      t.index [:jid], unique: true
      t.index [:status]
      t.index [:project_id, :status]
    end
  end
  # rubocop:enable Migration/PreventStrings
end
