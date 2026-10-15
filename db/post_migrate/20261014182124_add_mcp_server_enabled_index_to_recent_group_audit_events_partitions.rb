# frozen_string_literal: true

class AddMcpServerEnabledIndexToRecentGroupAuditEventsPartitions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.6'

  disable_ddl_transaction!

  TABLE_NAME = :group_audit_events
  INDEX_NAME = 'tmp_idx_group_audit_events_on_group_id_created_at_mcp_enabled'
  COLUMNS = [:group_id, :created_at, :id]
  WHERE_CLAUSE = "event_name = 'mcp_server_enabled_updated'"
  # McpServerDefaultTrueForGroups only reads events from 2026-06-18 onward.
  FIRST_PARTITION = "#{TABLE_NAME}_202606"

  # Builds now, on the monthly partitions the migration reads, the per-partition indexes that
  # PrepareMcpServerEnabledIndexOnGroupAuditEvents queued, using the same names. The weekend
  # async job skips them. Only GitLab.com queues the migration, so other installs leave the
  # indexes to the async job. The parent index is created later in
  # https://gitlab.com/gitlab-org/gitlab/-/work_items/631175
  def up
    return unless Gitlab.com_except_jh?

    recent_partitions.each do |partition|
      add_concurrent_index(
        partition.identifier,
        COLUMNS,
        name: generated_index_name(partition.identifier, INDEX_NAME),
        where: WHERE_CLAUSE,
        allow_partition: true
      )
    end
  end

  def down
    return unless Gitlab.com_except_jh?

    recent_partitions.each do |partition|
      # rubocop:disable Migration/RemoveIndex -- remove_concurrent_index_by_name refuses partitions; this drops concurrently
      remove_index(
        partition.identifier,
        name: generated_index_name(partition.identifier, INDEX_NAME),
        algorithm: :concurrently,
        if_exists: true
      )
      # rubocop:enable Migration/RemoveIndex
    end
  end

  private

  def recent_partitions
    find_partitioned_table(TABLE_NAME).postgres_partitions.order(:name).select do |partition|
      partition.name >= FIRST_PARTITION
    end
  end
end
