# frozen_string_literal: true

class PrepareAsyncIndexForBuildsPart4 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '16.10'
  disable_ddl_transaction!

  INDEXES = [
    {
      name: 'p_ci_builds_runner_id_bigint_idx',
      columns: [:runner_id_convert_to_bigint],
      options: { where: "status::text = 'running'::text AND type::text = 'Ci::Build'::text" }
    },
    {
      name: 'p_ci_builds_status_type_runner_id_bigint_idx',
      columns: [:status, :type, :runner_id_convert_to_bigint]
    },
    {
      name: 'p_ci_builds_project_id_bigint_id_idx',
      columns: [:project_id_convert_to_bigint, :id]
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
