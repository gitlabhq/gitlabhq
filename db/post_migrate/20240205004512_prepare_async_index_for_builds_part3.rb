# frozen_string_literal: true

class PrepareAsyncIndexForBuildsPart3 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '16.9'
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
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      INDEXES.each do |definition|
        name, columns, options = definition.values_at(:name, :columns, :options)
        index_name = generated_index_name(partition.identifier, name)
        prepare_async_index partition.identifier, columns, name: index_name, **(options || {})
      end
    end
  end

  def down
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      INDEXES.each do |definition|
        name, columns, options = definition.values_at(:name, :columns, :options)
        index_name = generated_index_name(partition.identifier, name)
        unprepare_async_index partition.identifier, columns, name: index_name, **(options || {})
      end
    end
  end
end
