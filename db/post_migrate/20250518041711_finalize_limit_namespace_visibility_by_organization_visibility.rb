# frozen_string_literal: true

class FinalizeLimitNamespaceVisibilityByOrganizationVisibility < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "LimitNamespaceVisibilityByOrganizationVisibility"

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :namespaces,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
