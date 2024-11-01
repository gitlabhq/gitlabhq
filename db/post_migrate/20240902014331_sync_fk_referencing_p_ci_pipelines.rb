# frozen_string_literal: true

class SyncFkReferencingPCiPipelines < Gitlab::Database::Migration[2.2]
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

  OLD_REFERENCING_TABLE = :ci_pipelines
  NEW_REFERENCING_TABLE = :p_ci_pipelines

  def up
    FOREIGN_KEYS.each do |options|
      with_lock_retries do
        validate_foreign_key(options[:source_table], options[:column], name: options[:name])
      end
      replace_foreign_key_for_new_referencing_table(options)
    end

    P_FOREIGN_KEYS.each do |options|
      add_concurrent_partitioned_foreign_key(
        options[:source_table], NEW_REFERENCING_TABLE,
        **with_defaults(options, validate: true)
      )
      replace_foreign_key_for_new_referencing_table(options, partitioned: true)
    end
  end

  def down
    FOREIGN_KEYS.each do |options|
      restore_foreign_key_for_old_source_table(options)

      add_concurrent_foreign_key(
        options[:source_table], NEW_REFERENCING_TABLE,
        **with_defaults(options, validate: false)
      )
    end

    P_FOREIGN_KEYS.each do |options|
      restore_foreign_key_for_old_source_table(options, partitioned: true)

      add_concurrent_partitioned_foreign_key(
        options[:source_table], NEW_REFERENCING_TABLE,
        **with_defaults(options, validate: false)
      )
    end
  end

  private

  def with_defaults(options, validate:, name: nil)
    options.except(:source_table).with_defaults(
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      reverse_lock_order: true,
      validate: validate
    ).tap { |opts| opts[:name] = name if name.present? }
  end

  def replace_foreign_key_for_new_referencing_table(options, partitioned: false)
    target_fk_name = options[:name].to_s.gsub('_tmp', '')
    with_lock_retries do
      remove_foreign_key_if_exists(old_source_table(options), name: target_fk_name, reverse_lock_order: true)

      if partitioned
        rename_partitioned_foreign_key(options[:source_table], options[:name], target_fk_name)
      else
        rename_constraint(options[:source_table], options[:name], target_fk_name)
      end
    end
  end

  def restore_foreign_key_for_old_source_table(options, partitioned: false)
    target_fk_name = options[:name].to_s.gsub('_tmp', '')
    with_lock_retries do
      remove_foreign_key_if_exists(options[:source_table], name: target_fk_name, reverse_lock_order: true)
    end

    if partitioned && old_source_table(options) == options[:source_table]
      add_concurrent_partitioned_foreign_key(
        old_source_table(options), OLD_REFERENCING_TABLE,
        **with_defaults(options, name: target_fk_name, validate: true)
      )
    else
      add_concurrent_foreign_key(
        old_source_table(options), OLD_REFERENCING_TABLE,
        **with_defaults(options, name: target_fk_name, validate: true)
      )
    end
  end

  def old_source_table(options)
    return OLD_REFERENCING_TABLE if options[:source_table] == NEW_REFERENCING_TABLE

    options[:source_table]
  end
end
