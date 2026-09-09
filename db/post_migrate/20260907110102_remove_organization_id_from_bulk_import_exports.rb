# frozen_string_literal: true

class RemoveOrganizationIdFromBulkImportExports < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  TABLE_NAME = :bulk_import_exports

  def up
    return unless table_exists?(TABLE_NAME)

    with_lock_retries do
      remove_column TABLE_NAME, :organization_id, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column TABLE_NAME, :organization_id, :bigint unless column_exists?(TABLE_NAME, :organization_id)
    end
  end
end
