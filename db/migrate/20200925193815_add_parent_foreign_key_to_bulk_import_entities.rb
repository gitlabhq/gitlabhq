# frozen_string_literal: true

class AddParentForeignKeyToBulkImportEntities < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :bulk_import_entities, :bulk_import_entities, column: :parent_id, on_delete: :cascade
  end

  def down
    remove_foreign_key :bulk_import_entities, column: :parent_id
  end
end
