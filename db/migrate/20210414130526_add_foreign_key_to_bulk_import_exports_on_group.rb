# frozen_string_literal: true

class AddForeignKeyToBulkImportExportsOnGroup < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :bulk_import_exports, :namespaces, column: :group_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :bulk_import_exports, column: :group_id
    end
  end
end
