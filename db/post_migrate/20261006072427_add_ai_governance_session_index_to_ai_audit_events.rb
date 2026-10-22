# frozen_string_literal: true

class AddAiGovernanceSessionIndexToAiAuditEvents < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '19.6'

  TABLE_NAME = :ai_audit_events
  INDEX_NAME = 'idx_ai_audit_events_on_ai_governance_session_id_created_at_id'

  def up
    add_concurrent_partitioned_index(
      TABLE_NAME,
      [:ai_governance_session_id, :created_at, :id],
      order: { created_at: :desc, id: :desc },
      name: INDEX_NAME,
      where: 'ai_governance_session_id IS NOT NULL'
    )
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
