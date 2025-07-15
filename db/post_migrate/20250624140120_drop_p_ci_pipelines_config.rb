# frozen_string_literal: true

class DropPCiPipelinesConfig < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  INDEX_NAME = :index_p_ci_pipelines_config_on_project_id

  disable_ddl_transaction!

  milestone '18.3'

  def up
    with_lock_retries do
      drop_table :p_ci_pipelines_config
    end
  end

  def down
    creation_opts = {
      primary_key: [:pipeline_id, :partition_id],
      options: 'PARTITION BY LIST (partition_id)',
      if_not_exists: true
    }

    create_table :p_ci_pipelines_config, **creation_opts do |t|
      t.bigint :pipeline_id, null: false
      t.bigint :partition_id, null: false
      t.bigint :project_id
      t.text :content, null: false
    end

    add_not_null_constraint :p_ci_pipelines_config, :project_id
    add_concurrent_partitioned_index(:p_ci_pipelines_config, :project_id, name: INDEX_NAME)
  end
end
