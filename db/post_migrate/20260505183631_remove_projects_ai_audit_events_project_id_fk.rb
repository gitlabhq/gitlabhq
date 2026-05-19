# frozen_string_literal: true

class RemoveProjectsAiAuditEventsProjectIdFk < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.0'
  disable_ddl_transaction!

  def up
    remove_partitioned_foreign_key :ai_audit_events, column: :project_id
  end

  def down
    add_concurrent_partitioned_foreign_key(
      :ai_audit_events,
      :projects,
      column: :project_id,
      on_delete: :cascade,
      reverse_lock_order: true
    )
  end
end
