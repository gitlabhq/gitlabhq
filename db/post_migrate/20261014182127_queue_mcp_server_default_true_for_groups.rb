# frozen_string_literal: true

class QueueMcpServerDefaultTrueForGroups < Gitlab::Database::Migration[2.3]
  milestone '19.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "McpServerDefaultTrueForGroups"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  # Group MCP settings are only enforced on GitLab.com (mcp_server_saas_only).
  def up
    return unless Gitlab.com_except_jh?

    queue_batched_background_migration(
      MIGRATION,
      :namespaces,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      max_batch_size: 5_000
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :namespaces, :id, [])
  end
end
