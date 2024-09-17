# frozen_string_literal: true

class SwapPrimaryKeyForCiPipelinesToIncludePartitionId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.4'
  disable_ddl_transaction!

  TABLE_NAME = :ci_pipelines
  PRIMARY_KEY = :ci_pipelines_pkey
  OLD_INDEX_NAME = :index_ci_pipelines_on_id
  NEW_INDEX_NAME = :index_ci_pipelines_on_id_and_partition_id

  def up
    swap_primary_key(TABLE_NAME, PRIMARY_KEY, NEW_INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, :id, unique: true, name: OLD_INDEX_NAME)
    add_concurrent_index(TABLE_NAME, [:id, :partition_id], unique: true, name: NEW_INDEX_NAME)

    unswap_primary_key(TABLE_NAME, PRIMARY_KEY, OLD_INDEX_NAME)

    recreate_partitioned_foreign_keys
  end

  private

  def recreate_partitioned_foreign_keys
    add_partitioned_fk(:ci_pipelines, :fk_262d4c2d19_p,
      columns: [:auto_canceled_by_partition_id, :auto_canceled_by_id], on_delete: :nullify)
    add_partitioned_fk(:ci_pipeline_chat_data, :fk_64ebfab6b3_p)
    add_partitioned_fk(:ci_sources_pipelines, :fk_d4e29af7d7_p, columns: [:source_partition_id, :source_pipeline_id])
    add_partitioned_fk(:ci_sources_pipelines, :fk_e1bad85861_p)
    add_partitioned_fk(:ci_sources_projects, :fk_rails_10a1eb379a_p)
    add_partitioned_fk(:ci_pipeline_metadata, :fk_rails_50c1e9ea10_p)
    add_partitioned_fk(:ci_pipeline_messages, :fk_rails_8d3b04e3e1_p)
    add_partitioned_fk(:ci_pipelines_config, :fk_rails_906c9a2533_p)
    add_partitioned_fk(:ci_pipeline_artifacts, :fk_rails_a9e811a466_p)
    add_partitioned_fk(:ci_daily_build_group_report_results, :fk_rails_ee072d13b3_p,
      columns: [:partition_id, :last_pipeline_id])

    add_routing_table_fk(:p_ci_builds, :fk_87f4cefcda_p,
      columns: [:upstream_pipeline_partition_id, :upstream_pipeline_id])
    add_routing_table_fk(:p_ci_builds, :fk_a2141b1522_p,
      columns: [:auto_canceled_by_partition_id, :auto_canceled_by_id],
      on_delete: :nullify)
    add_routing_table_fk(:p_ci_builds, :fk_d3130c9a7f_p,
      columns: [:partition_id, :commit_id])
    add_routing_table_fk(:p_ci_pipeline_variables, :fk_f29c5f4380_p)
    add_routing_table_fk(:p_ci_stages, :fk_fb57e6cc56_p)
    add_routing_table_fk(:p_ci_builds_execution_configs, :fk_rails_c26408d02c_p)
  end

  def add_partitioned_fk(source_table, name, column: :pipeline_id, columns: nil, on_delete: :cascade)
    add_concurrent_foreign_key(source_table, :ci_pipelines,
      column: columns || [:partition_id, column],
      target_column: [:partition_id, :id],
      reverse_lock_order: true,
      on_update: :cascade,
      on_delete: on_delete,
      name: name)
  end

  def add_routing_table_fk(source_table, name, columns: nil, on_delete: :cascade)
    add_concurrent_partitioned_foreign_key(source_table, :ci_pipelines,
      column: columns || [:partition_id, :pipeline_id],
      target_column: [:partition_id, :id],
      reverse_lock_order: true,
      on_update: :cascade,
      on_delete: on_delete,
      name: name)
  end
end
