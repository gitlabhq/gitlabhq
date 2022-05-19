# frozen_string_literal: true

# This migration acts as a gate-keeper for other migrations related to project namespace back-filling
# so that other migrations that depend on project namespace back-filling cannot be run unless project namespace
# back-filling has finalized successfully.
class FinalizeProjectNamespacesBackfill < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  MIGRATION = 'ProjectNamespaces::BackfillProjectNamespaces'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :projects,
      column_name: :id,
      job_arguments: [nil, 'up']
    )
  end

  def down
    # noop
  end
end
