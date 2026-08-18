# frozen_string_literal: true

class DropPCiBuildsExecutionConfigs < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers

  disable_ddl_transaction!
  milestone '19.3'

  TABLE_NAME = :p_ci_builds_execution_configs
  SEQ_NAME = :p_ci_builds_execution_configs_id_seq

  OPTIONS = {
    primary_key: [:id, :partition_id],
    options: 'PARTITION BY LIST (partition_id)',
    if_not_exists: true
  }

  def up
    revert_ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)

    with_lock_retries do
      drop_table TABLE_NAME, if_exists: true
    end
  end

  def down
    with_lock_retries do
      create_table TABLE_NAME, **OPTIONS do |t|
        t.bigserial :id, null: false
        t.bigint :partition_id, null: false
        t.bigint :project_id, null: false
        t.bigint :pipeline_id, null: false
        t.jsonb :run_steps, null: false, default: {}
        t.index :pipeline_id, name: 'index_p_ci_builds_execution_configs_on_pipeline_id'
        t.index :project_id, name: 'index_p_ci_builds_execution_configs_on_project_id'
      end
    end

    ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end
end
