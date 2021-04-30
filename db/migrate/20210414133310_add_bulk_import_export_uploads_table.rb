# frozen_string_literal: true

class AddBulkImportExportUploadsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    create_table_with_constraints :bulk_import_export_uploads do |t|
      t.references :export, index: true, null: false, foreign_key: { to_table: :bulk_import_exports, on_delete: :cascade }
      t.datetime_with_timezone :updated_at, null: false
      t.text :export_file

      t.text_limit :export_file, 255
    end
  end

  def down
    drop_table :bulk_import_export_uploads
  end
end
