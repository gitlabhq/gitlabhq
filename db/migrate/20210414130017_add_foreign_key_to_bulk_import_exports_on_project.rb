# frozen_string_literal: true

class AddForeignKeyToBulkImportExportsOnProject < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :bulk_import_exports, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :bulk_import_exports, column: :project_id
    end
  end
end
