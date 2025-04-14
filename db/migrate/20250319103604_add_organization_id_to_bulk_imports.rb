# frozen_string_literal: true

class AddOrganizationIdToBulkImports < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.11'

  def up
    with_lock_retries { add_column :bulk_imports, :organization_id, :bigint, if_not_exists: true }

    add_concurrent_index :bulk_imports, :organization_id

    add_concurrent_foreign_key :bulk_imports, :organizations, column: :organization_id, on_delete: :cascade
  end

  def down
    with_lock_retries { remove_column :bulk_imports, :organization_id, if_exists: true }
  end
end
