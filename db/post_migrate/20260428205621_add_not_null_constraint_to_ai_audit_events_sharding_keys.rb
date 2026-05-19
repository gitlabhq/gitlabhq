# frozen_string_literal: true

class AddNotNullConstraintToAiAuditEventsShardingKeys < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint :ai_audit_events, :project_id, :namespace_id
  end

  def down
    remove_multi_column_not_null_constraint :ai_audit_events, :project_id, :namespace_id
  end
end
