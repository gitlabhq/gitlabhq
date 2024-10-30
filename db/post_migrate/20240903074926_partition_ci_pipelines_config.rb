# frozen_string_literal: true

class PartitionCiPipelinesConfig < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  def up
    return if already_partitioned?

    with_lock_retries do
      lock_tables(:p_ci_pipelines, :ci_pipelines_config, mode: :access_exclusive)

      drop_table(:ci_pipelines_config)

      connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS ci_pipelines_config
          PARTITION OF p_ci_pipelines_config
          FOR VALUES IN (100, 101, 102);
      SQL
    end
  end

  def down
    drop_table(:ci_pipelines_config, if_exists: true)

    create_table(:ci_pipelines_config, id: false, if_not_exists: true) do |t|
      t.bigint :pipeline_id, null: false, default: nil, primary_key: true
      t.text :content, null: false
      t.bigint :partition_id, null: false
    end

    add_concurrent_foreign_key(
      :ci_pipelines_config, :p_ci_pipelines,
      column: [:partition_id, :pipeline_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      reverse_lock_order: true,
      name: :fk_rails_906c9a2533_p
    )
  end

  private

  def already_partitioned?
    ::Gitlab::Database::PostgresPartition
      .for_parent_table(:p_ci_pipelines_config)
      .any?
  end
end
