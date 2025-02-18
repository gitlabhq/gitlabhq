# frozen_string_literal: true

class AddOrganizationIdToImportFailures < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  def up
    with_lock_retries { add_column :import_failures, :organization_id, :bigint, if_not_exists: true }

    add_concurrent_index :import_failures, :organization_id

    add_concurrent_index(
      :import_failures,
      :id,
      where: "organization_id IS NULL AND project_id IS NULL AND group_id IS NULL",
      name: "idx_import_failures_where_organization_project_and_group_null"
    )

    add_concurrent_foreign_key(
      :import_failures,
      :organizations,
      column: :organization_id,
      foreign_key: true,
      on_delete: :cascade
    )
  end

  def down
    with_lock_retries { remove_column :import_failures, :organization_id, if_exists: true }
  end
end
