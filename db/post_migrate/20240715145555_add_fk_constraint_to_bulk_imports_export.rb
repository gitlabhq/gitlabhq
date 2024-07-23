# frozen_string_literal: true

class AddFkConstraintToBulkImportsExport < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.3'

  TABLE_NAME = :bulk_import_exports
  COLUMN_NAME = :user_id

  def up
    add_concurrent_foreign_key TABLE_NAME, :users, column: COLUMN_NAME, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key TABLE_NAME, column: COLUMN_NAME
    end
  end
end
