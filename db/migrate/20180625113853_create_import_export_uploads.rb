class CreateImportExportUploads < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  def change
    create_table :import_export_uploads do |t|
      t.datetime_with_timezone :updated_at, null: false

      t.references :project, index: true, foreign_key: { on_delete: :cascade }, unique: true

      t.text :import_file
      t.text :export_file
    end

    add_index :import_export_uploads, :updated_at
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
