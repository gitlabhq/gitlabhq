# frozen_string_literal: true

class SyncIndexForPCiBuildsPart3 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '16.10'
  disable_ddl_transaction!

  INDEXES = [
    {
      name: 'p_ci_builds_resource_group_id_status_commit_id_bigint_idx',
      columns: [:resource_group_id, :status, :commit_id_convert_to_bigint],
      options: { where: 'resource_group_id IS NOT NULL' }
    },
    {
      name: 'p_ci_builds_commit_id_bigint_stage_idx_created_at_idx',
      columns: [:commit_id_convert_to_bigint, :stage_idx, :created_at]
    },
    {
      name: 'p_ci_builds_runner_id_bigint_id_idx',
      columns: [:runner_id_convert_to_bigint, :id],
      options: { order: { id: :desc } }
    }
  ]
  TABLE_NAME = :p_ci_builds

  def up
    INDEXES.each do |definition|
      name, columns, options = definition.values_at(:name, :columns, :options)
      add_concurrent_partitioned_index(TABLE_NAME, columns, name: name, **(options || {}))
    end
  end

  def down
    INDEXES.each do |definition|
      name = definition[:name]
      remove_concurrent_partitioned_index_by_name(TABLE_NAME, name)
    end
  end
end
