# frozen_string_literal: true

class CreateTableCiWorkloadVariableInclusions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.3'
  disable_ddl_transaction!

  def up
    # Create p_ci_workload_variable_inclusions
    create_table(:p_ci_workload_variable_inclusions, primary_key: [:id, :partition_id], # rubocop:disable Migration/EnsureFactoryForTable -- exists at spec/factories/ci/workloads/variable_inclusions.rb
      options: 'PARTITION BY LIST (partition_id)', if_not_exists: true) do |t|
      t.bigserial :id, null: false
      t.bigint :workload_id
      t.bigint :partition_id, null: false
      t.bigint :project_id, null: false, index: true

      t.timestamps_with_timezone null: false

      t.text :variable_name, null: false, limit: 255
    end

    add_concurrent_partitioned_index :p_ci_workload_variable_inclusions, [:workload_id, :partition_id],
      name: :p_ci_workload_variable_inclusions_workload_id_idx

    add_concurrent_partitioned_foreign_key(
      :p_ci_workload_variable_inclusions, :p_ci_workloads,
      column: [:partition_id, :workload_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      reverse_lock_order: true
    )

    # Create first partitions of p_ci_workload_variable_inclusions
    with_lock_retries do
      connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_workload_variable_inclusions_100
          PARTITION OF p_ci_workload_variable_inclusions
          FOR VALUES IN (100);

        CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_workload_variable_inclusions_101
          PARTITION OF p_ci_workload_variable_inclusions
          FOR VALUES IN (101);

        CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_workload_variable_inclusions_102
          PARTITION OF p_ci_workload_variable_inclusions
          FOR VALUES IN (102);

        CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_workload_variable_inclusions_103
          PARTITION OF p_ci_workload_variable_inclusions
          FOR VALUES IN (103);

        CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_workload_variable_inclusions_104
          PARTITION OF p_ci_workload_variable_inclusions
          FOR VALUES IN (104);

        CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_workload_variable_inclusions_105
          PARTITION OF p_ci_workload_variable_inclusions
          FOR VALUES IN (105);

        CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_workload_variable_inclusions_106
          PARTITION OF p_ci_workload_variable_inclusions
          FOR VALUES IN (106);
      SQL
    end
  end

  def down
    drop_table :p_ci_workload_variable_inclusions, if_exists: true
  end
end
