# frozen_string_literal: true

class CreateCiWorkloads < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.0'
  disable_ddl_transaction!

  def up
    # Create p_ci_workloads
    create_table(:p_ci_workloads, primary_key: [:id, :partition_id], # rubocop:disable Migration/EnsureFactoryForTable -- exists in spec/factories/ci/workloads/workloads.rb
      options: 'PARTITION BY LIST (partition_id)', if_not_exists: true) do |t|
      t.bigserial :id, null: false
      t.bigint :partition_id, null: false
      t.bigint :project_id, null: false, index: true
      t.bigint :pipeline_id, null: false
      t.timestamps_with_timezone null: false
      t.text :branch_name, null: true, limit: 255
    end

    add_concurrent_partitioned_index :p_ci_workloads, [:pipeline_id, :partition_id], unique: true,
      name: :p_ci_workloads_pipeline_id_idx

    # Create first partitions of p_ci_workloads
    with_lock_retries do
      connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_workloads_100
          PARTITION OF p_ci_workloads
          FOR VALUES IN (100);

        CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_workloads_101
          PARTITION OF p_ci_workloads
          FOR VALUES IN (101);

        CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_workloads_102
          PARTITION OF p_ci_workloads
          FOR VALUES IN (102);

        CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_workloads_103
          PARTITION OF p_ci_workloads
          FOR VALUES IN (103);
      SQL
    end

    # Create join table with duo_workflows_workflows
    create_table :duo_workflows_workloads, if_not_exists: true do |t| # rubocop:disable Migration/EnsureFactoryForTable -- exists in ee/spec/factories/ai/duo_workflows/workflows_workloads.rb
      t.bigint :project_id, null: false, index: true
      t.bigint :workflow_id, null: false, index: true
      t.bigint :workload_id, null: false, index: true, unique: true
    end

    add_concurrent_foreign_key :duo_workflows_workloads, :projects, column: :project_id, on_delete: :cascade
    add_concurrent_foreign_key :duo_workflows_workloads, :duo_workflows_workflows, column: :workflow_id,
      on_delete: :cascade
  end

  def down
    drop_table :duo_workflows_workloads, if_exists: true
    drop_table :p_ci_workloads, if_exists: true
  end
end
