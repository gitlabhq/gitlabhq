# frozen_string_literal: true

class PrepareMcpServerEnabledIndexOnGroupAuditEvents < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.5'

  disable_ddl_transaction!

  TABLE_NAME = :group_audit_events
  INDEX_NAME = 'tmp_idx_group_audit_events_on_group_id_created_at_mcp_enabled'

  # Only McpServerDefaultTrueForGroups looks up MCP audit events by name, so this index is temporary.
  # TODO: Partitioned index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/work_items/631175
  # Temporary index to be removed in 19.7 https://gitlab.com/gitlab-org/gitlab/-/work_items/631178
  def up
    prepare_partitioned_async_index(
      TABLE_NAME,
      [:group_id, :created_at, :id],
      name: INDEX_NAME,
      where: "event_name = 'mcp_server_enabled_updated'"
    )
  end

  def down
    unprepare_partitioned_async_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
