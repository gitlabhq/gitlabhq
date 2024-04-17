# frozen_string_literal: true

class SyncIndexForPCiBuildsPart4 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.0'
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
