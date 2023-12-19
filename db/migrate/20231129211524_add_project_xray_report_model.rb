# frozen_string_literal: true

class AddProjectXrayReportModel < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.7'

  def change
    create_table :xray_reports, if_not_exists: true do |t|
      # we create an index manually below, don't create one here
      t.references :project, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.text :lang, null: false, limit: 255
      t.jsonb :payload, null: false
      t.binary :file_checksum, null: false
    end

    add_index :xray_reports, [:project_id, :lang], unique: true, name: 'index_xray_reports_on_project_id_and_lang'
  end
end
