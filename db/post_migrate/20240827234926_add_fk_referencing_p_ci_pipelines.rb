# frozen_string_literal: true

class AddFkReferencingPCiPipelines < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.4'
  disable_ddl_transaction!

  FOREIGN_KEYS = [
    {
      source_table: :ci_pipeline_chat_data,
      name: :fk_64ebfab6b3_p_tmp,
      column: [:partition_id, :pipeline_id]
    },
    {
      source_table: :ci_sources_pipelines,
      name: :fk_d4e29af7d7_p_tmp,
      column: [:source_partition_id, :source_pipeline_id]
    },
    {
      source_table: :ci_sources_pipelines,
      name: :fk_e1bad85861_p_tmp,
      column: [:partition_id, :pipeline_id]
    },
    {
      source_table: :ci_sources_projects,
      name: :fk_rails_10a1eb379a_p_tmp,
      column: [:partition_id, :pipeline_id]
    },
    {
      source_table: :ci_pipeline_metadata,
      name: :fk_rails_50c1e9ea10_p_tmp,
      column: [:partition_id, :pipeline_id]
    },
    {
      source_table: :ci_pipeline_messages,
      name: :fk_rails_8d3b04e3e1_p_tmp,
      column: [:partition_id, :pipeline_id]
    },
    {
      source_table: :ci_pipelines_config,
      name: :fk_rails_906c9a2533_p_tmp,
      column: [:partition_id, :pipeline_id]
    },
    {
      source_table: :ci_pipeline_artifacts,
      name: :fk_rails_a9e811a466_p_tmp,
      column: [:partition_id, :pipeline_id]
    },
    {
      source_table: :ci_daily_build_group_report_results,
      name: :fk_rails_ee072d13b3_p_tmp,
      column: [:partition_id, :last_pipeline_id]
    }
  ]

  P_FOREIGN_KEYS = [
    {
      source_table: :p_ci_pipelines,
      name: :fk_262d4c2d19_p_tmp,
      column: [:auto_canceled_by_partition_id, :auto_canceled_by_id],
      on_delete: :nullify
    },
    {
      source_table: :p_ci_builds,
      name: :fk_87f4cefcda_p_tmp,
      column: [:upstream_pipeline_partition_id, :upstream_pipeline_id]
    },
    {
      source_table: :p_ci_builds,
      name: :fk_a2141b1522_p_tmp,
      column: [:auto_canceled_by_partition_id, :auto_canceled_by_id],
      on_delete: :nullify
    },
    {
      source_table: :p_ci_builds,
      name: :fk_d3130c9a7f_p_tmp,
      column: [:partition_id, :commit_id]
    },
    {
      source_table: :p_ci_pipeline_variables,
      name: :fk_f29c5f4380_p_tmp,
      column: [:partition_id, :pipeline_id]
    },
    {
      source_table: :p_ci_stages,
      name: :fk_fb57e6cc56_p_tmp,
      column: [:partition_id, :pipeline_id]
    },
    {
      source_table: :p_ci_builds_execution_configs,
      name: :fk_rails_c26408d02c_p_tmp,
      column: [:partition_id, :pipeline_id]
    }
  ]

  def up
    FOREIGN_KEYS.each do |fk|
      add_concurrent_foreign_key(fk[:source_table], :p_ci_pipelines, **with_defaults(fk))
      prepare_async_foreign_key_validation(fk[:source_table], name: fk[:name])
    end

    P_FOREIGN_KEYS.each do |fk|
      add_concurrent_partitioned_foreign_key(fk[:source_table], :p_ci_pipelines, **with_defaults(fk))
      prepare_partitioned_async_foreign_key_validation(fk[:source_table], name: fk[:name])
    end
  end

  def down
    FOREIGN_KEYS.each do |fk|
      unprepare_async_foreign_key_validation(fk[:source_table], name: fk[:name])
      with_lock_retries do
        remove_foreign_key_if_exists(fk[:source_table], name: fk[:name], reverse_lock_order: true)
      end
    end

    P_FOREIGN_KEYS.each do |fk|
      unprepare_partitioned_async_foreign_key_validation(fk[:source_table], name: fk[:name])
      Gitlab::Database::PostgresPartitionedTable.each_partition(fk[:source_table]) do |partition|
        with_lock_retries do
          remove_foreign_key_if_exists partition.identifier, name: fk[:name], reverse_lock_order: true
        end
      end
    end
  end

  private

  def with_defaults(options)
    options.except(:source_table).with_defaults(
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      reverse_lock_order: true,
      validate: false
    )
  end
end
