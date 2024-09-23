# frozen_string_literal: true

class ConvertCiPipelinesToListPartitioning < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '17.4'
  disable_ddl_transaction!

  TABLE_NAME = :ci_pipelines
  PARENT_TABLE_NAME = :p_ci_pipelines
  FIRST_PARTITION = (100..102).to_a
  PARTITION_COLUMN = :partition_id

  FOREIGN_KEYS = [
    {
      name: "fk_64ebfab6b3_p",
      constrained_table_name: "ci_pipeline_chat_data",
      constrained_columns: %w[
        partition_id
        pipeline_id
      ],
      referenced_columns: %w[
        partition_id
        id
      ],
      on_delete_action: :cascade,
      on_update_action: :cascade
    },
    {
      name: "fk_87f4cefcda_p",
      constrained_table_name: "p_ci_builds",
      constrained_columns: %w[
        upstream_pipeline_partition_id
        upstream_pipeline_id
      ],
      referenced_columns: %w[
        partition_id
        id
      ],
      on_delete_action: :cascade,
      on_update_action: :cascade
    },
    {
      name: "fk_a2141b1522_p",
      constrained_table_name: "p_ci_builds",
      constrained_columns: %w[
        auto_canceled_by_partition_id
        auto_canceled_by_id
      ],
      referenced_columns: %w[
        partition_id
        id
      ],
      on_delete_action: :nullify,
      on_update_action: :cascade
    },
    {
      name: "fk_d3130c9a7f_p",
      constrained_table_name: "p_ci_builds",
      constrained_columns: %w[
        partition_id
        commit_id
      ],
      referenced_columns: %w[
        partition_id
        id
      ],
      on_delete_action: :cascade,
      on_update_action: :cascade
    },
    {
      name: "fk_d4e29af7d7_p",
      constrained_table_name: "ci_sources_pipelines",
      constrained_columns: %w[
        source_partition_id
        source_pipeline_id
      ],
      referenced_columns: %w[
        partition_id
        id
      ],
      on_delete_action: :cascade,
      on_update_action: :cascade
    },
    {
      name: "fk_e1bad85861_p",
      constrained_table_name: "ci_sources_pipelines",
      constrained_columns: %w[
        partition_id
        pipeline_id
      ],
      referenced_columns: %w[
        partition_id
        id
      ],
      on_delete_action: :cascade,
      on_update_action: :cascade
    },
    {
      name: "fk_f29c5f4380_p",
      constrained_table_name: "p_ci_pipeline_variables",
      constrained_columns: %w[
        partition_id
        pipeline_id
      ],
      referenced_columns: %w[
        partition_id
        id
      ],
      on_delete_action: :cascade,
      on_update_action: :cascade
    },
    {
      name: "fk_fb57e6cc56_p",
      constrained_table_name: "p_ci_stages",
      constrained_columns: %w[
        partition_id
        pipeline_id
      ],
      referenced_columns: %w[
        partition_id
        id
      ],
      on_delete_action: :cascade,
      on_update_action: :cascade
    },
    {
      name: "fk_rails_10a1eb379a_p",
      constrained_table_name: "ci_sources_projects",
      constrained_columns: %w[
        partition_id
        pipeline_id
      ],
      referenced_columns: %w[
        partition_id
        id
      ],
      on_delete_action: :cascade,
      on_update_action: :cascade
    },
    {
      name: "fk_rails_50c1e9ea10_p",
      constrained_table_name: "ci_pipeline_metadata",
      constrained_columns: %w[
        partition_id
        pipeline_id
      ],
      referenced_columns: %w[
        partition_id
        id
      ],
      on_delete_action: :cascade,
      on_update_action: :cascade
    },
    {
      name: "fk_rails_8d3b04e3e1_p",
      constrained_table_name: "ci_pipeline_messages",
      constrained_columns: %w[
        partition_id
        pipeline_id
      ],
      referenced_columns: %w[
        partition_id
        id
      ],
      on_delete_action: :cascade,
      on_update_action: :cascade
    },
    {
      name: "fk_rails_906c9a2533_p",
      constrained_table_name: "ci_pipelines_config",
      constrained_columns: %w[
        partition_id
        pipeline_id
      ],
      referenced_columns: %w[
        partition_id
        id
      ],
      on_delete_action: :cascade,
      on_update_action: :cascade
    },
    {
      name: "fk_rails_a9e811a466_p",
      constrained_table_name: "ci_pipeline_artifacts",
      constrained_columns: %w[
        partition_id
        pipeline_id
      ],
      referenced_columns: %w[
        partition_id
        id
      ],
      on_delete_action: :cascade,
      on_update_action: :cascade
    },
    {
      name: "fk_rails_c26408d02c_p",
      constrained_table_name: "p_ci_builds_execution_configs",
      constrained_columns: %w[
        partition_id
        pipeline_id
      ],
      referenced_columns: %w[
        partition_id
        id
      ],
      on_delete_action: :cascade,
      on_update_action: :cascade
    },
    {
      name: "fk_rails_ee072d13b3_p",
      constrained_table_name: "ci_daily_build_group_report_results",
      constrained_columns: %w[
        partition_id
        last_pipeline_id
      ],
      referenced_columns: %w[
        partition_id
        id
      ],
      on_delete_action: :cascade,
      on_update_action: :cascade
    }
  ]

  def up
    convert_table_to_first_list_partition(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION
    )
  end

  def down
    FOREIGN_KEYS.each do |fk|
      with_lock_retries do
        remove_foreign_key_if_exists(fk[:constrained_table_name], name: fk[:name])
      end
    end

    revert_converting_table_to_first_list_partition(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION
    )

    FOREIGN_KEYS.each do |fk|
      add_concurrent_foreign_key(
        fk[:constrained_table_name],
        TABLE_NAME,
        name: fk[:name],
        column: fk[:constrained_columns],
        target_column: fk[:referenced_columns],
        on_delete: fk[:on_delete_action],
        on_update: fk[:on_update_action],
        validate: true,
        allow_partitioned: true
      )
    end
  end
end
