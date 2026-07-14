# frozen_string_literal: true

class AddCompositeWorkflowIndexToAiAuditEvents < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '19.1'

  TABLE_NAME = :ai_audit_events
  INDEX_NAME = 'idx_ai_audit_events_on_workflow_id_created_at_id'
  OLD_INDEX_NAME = 'idx_ai_audit_events_on_workflow_id'

  def up
    add_concurrent_partitioned_index(
      TABLE_NAME,
      [:workflow_id, :created_at, :id],
      order: { created_at: :desc, id: :desc },
      name: INDEX_NAME
    )

    remove_concurrent_partitioned_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_partitioned_index(TABLE_NAME, :workflow_id, name: OLD_INDEX_NAME)
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
