# frozen_string_literal: true

class CreateBulkImportEntities < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :bulk_import_entities, if_not_exists: true do |t|
      t.bigint :bulk_import_id, index: true, null: false
      t.bigint :parent_id, index: true
      t.bigint :namespace_id, index: true
      t.bigint :project_id, index: true

      t.integer :source_type, null: false, limit: 2
      t.text :source_full_path, null: false

      t.text :destination_name, null: false
      t.text :destination_namespace, null: false

      t.integer :status, null: false, limit: 2
      t.text :jid

      t.timestamps_with_timezone
    end

    add_text_limit(:bulk_import_entities, :source_full_path, 255)
    add_text_limit(:bulk_import_entities, :destination_name, 255)
    add_text_limit(:bulk_import_entities, :destination_namespace, 255)
    add_text_limit(:bulk_import_entities, :jid, 255)
  end

  def down
    drop_table :bulk_import_entities
  end
end
