# frozen_string_literal: true

class FinalizeHkBackfillArchivedInSecurityInventoryFilters < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillArchivedInSecurityInventoryFilters',
      table_name: :security_inventory_filters,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
