# frozen_string_literal: true

class SwapCiPipelinesPkWithBigintPCiBuildsPCiStages < Gitlab::Database::Migration[2.2]
  include ::Gitlab::Database::MigrationHelpers::Swapping
  include ::Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.0'
  disable_ddl_transaction!

  TABLE = :ci_pipelines
  COLUMNS = { new: :id_convert_to_bigint, old: :id }
  TRIGGER_FUNCTION = :trigger_b2d852e1e2cb
  LOOSE_FK_TRIGGER_FUNCTION = :insert_into_loose_foreign_keys_deleted_records
  PRIMARY_KEY = {
    name: :ci_pipelines_pkey,
    new_index: {
      name: :index_ci_pipelines_on_id_convert_to_bigint,
      columns: [:id_convert_to_bigint],
      options: { unique: true }
    }
  }

  INDEXES = [
    {
      name: :idx_ci_pipelines_artifacts_locked_bigint,
      old_name: :idx_ci_pipelines_artifacts_locked,
      columns: [:ci_ref_id, :id_convert_to_bigint],
      options: { where: 'locked = 1' }
    },
    {
      name: :index_ci_pipelines_for_ondemand_dast_scans_bigint,
      old_name: :index_ci_pipelines_for_ondemand_dast_scans,
      columns: [:id_convert_to_bigint],
      options: { where: 'source = 13' }
    },
    {
      name: :index_ci_pipelines_on_ci_ref_id_and_more_bigint,
      old_name: :index_ci_pipelines_on_ci_ref_id_and_more,
      columns: [:ci_ref_id, :id_convert_to_bigint, :source, :status],
      options: { order: { id_convert_to_bigint: :desc }, where: 'ci_ref_id IS NOT NULL' }
    },
    {
      name: :index_ci_pipelines_on_pipeline_schedule_id_and_id_bigint,
      old_name: :index_ci_pipelines_on_pipeline_schedule_id_and_id,
      columns: [:pipeline_schedule_id, :id_convert_to_bigint]
    },
    {
      name: :index_ci_pipelines_on_project_id_and_id_desc_bigint,
      old_name: :index_ci_pipelines_on_project_id_and_id_desc,
      columns: [:project_id, :id_convert_to_bigint],
      options: { order: { id_convert_to_bigint: :desc } }
    },
    {
      name: :idx_ci_pipelines_on_project_id_and_ref_and_status_and_id_bigint,
      old_name: :index_ci_pipelines_on_project_id_and_ref_and_status_and_id,
      columns: [:project_id, :ref, :status, :id_convert_to_bigint]
    },
    {
      name: :index_ci_pipelines_on_project_id_and_ref_and_id_desc_bigint,
      old_name: :index_ci_pipelines_on_project_idandrefandiddesc,
      columns: [:project_id, :ref, :id_convert_to_bigint],
      options: { order: { id_convert_to_bigint: :desc } }
    },
    {
      name: :index_ci_pipelines_on_status_and_id_bigint,
      old_name: :index_ci_pipelines_on_status_and_id,
      columns: [:status, :id_convert_to_bigint]
    },
    {
      name: :idx_ci_pipelines_on_user_id_and_id_and_cancelable_status_bigint,
      old_name: :index_ci_pipelines_on_user_id_and_id_and_cancelable_status,
      columns: [:user_id, :id_convert_to_bigint],
      options: { where: "((status)::text = ANY (ARRAY[('running'::character varying)::text, ('waiting_for_resource'::character varying)::text, ('preparing'::character varying)::text, ('pending'::character varying)::text, ('created'::character varying)::text, ('scheduled'::character varying)::text]))" }
    },
    {
      name: :idx_ci_pipelines_on_user_id_and_user_not_verified_bigint,
      old_name: :index_ci_pipelines_on_user_id_and_id_desc_and_user_not_verified,
      columns: [:user_id, :id_convert_to_bigint],
      options: { order: { id_convert_to_bigint: :desc }, where: "failure_reason = 3" }
    }
  ]

  FOREIGN_KEYS = [
    {
      source_table: :ci_pipelines,
      name: :fk_262d4c2d19,
      column: [:auto_canceled_by_id],
      on_delete: :nullify
    },
    {
      source_table: :ci_pipeline_chat_data,
      name: :fk_64ebfab6b3,
      column: [:pipeline_id],
      on_delete: :cascade
    },
    {
      source_table: :ci_sources_pipelines,
      name: :fk_d4e29af7d7,
      column: [:source_pipeline_id],
      on_delete: :cascade
    },
    {
      source_table: :ci_sources_pipelines,
      name: :fk_e1bad85861,
      column: [:pipeline_id],
      on_delete: :cascade
    },
    {
      source_table: :ci_sources_projects,
      name: :fk_rails_10a1eb379a,
      column: [:pipeline_id],
      on_delete: :cascade
    },
    {
      source_table: :ci_pipeline_metadata,
      name: :fk_rails_50c1e9ea10,
      column: [:pipeline_id],
      on_delete: :cascade
    },
    {
      source_table: :ci_pipeline_messages,
      name: :fk_rails_8d3b04e3e1,
      column: [:pipeline_id],
      on_delete: :cascade
    },
    {
      source_table: :ci_pipelines_config,
      name: :fk_rails_906c9a2533,
      column: [:pipeline_id],
      on_delete: :cascade
    },
    {
      source_table: :ci_pipeline_artifacts,
      name: :fk_rails_a9e811a466,
      column: [:pipeline_id],
      on_delete: :cascade
    },
    {
      source_table: :ci_daily_build_group_report_results,
      name: :fk_rails_ee072d13b3,
      column: [:last_pipeline_id],
      on_delete: :cascade
    }
  ]

  P_FOREIGN_KEYS = [
    {
      source_table: :p_ci_builds,
      name: :fk_87f4cefcda,
      column: [:upstream_pipeline_id],
      on_delete: :cascade
    },
    {
      source_table: :p_ci_builds,
      name: :fk_d3130c9a7f,
      column: [:commit_id],
      on_delete: :cascade
    },
    {
      source_table: :p_ci_builds,
      name: :fk_a2141b1522,
      column: [:auto_canceled_by_id],
      on_delete: :nullify
    },
    {
      source_table: :p_ci_pipeline_variables,
      name: :fk_f29c5f4380,
      column: [:pipeline_id],
      on_delete: :cascade
    },
    {
      source_table: :p_ci_stages,
      name: :fk_fb57e6cc56,
      column: [:pipeline_id],
      on_delete: :cascade
    }
  ]

  def up
    remove_integer_foreign_keys_and_rename_bigint
    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- custom implementation
    with_lock_retries(raise_on_exhaustion: true) do
      swap
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  def down
    remove_bigint_foreign_keys
    # Recover the indexes and for the **integer** column `id_convert_to_bigint`
    recover_indexes

    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- custom implementation
    with_lock_retries(raise_on_exhaustion: true) do
      swap
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod

    # Recover the indexes and for the **bigint** column `id_convert_to_bigint`
    recover_indexes
    recover_all_foreign_keys
  end

  private

  def swap
    swap_columns(TABLE, COLUMNS[:new], COLUMNS[:old])
    reset_trigger_function(TRIGGER_FUNCTION)
    reset_trigger_function(LOOSE_FK_TRIGGER_FUNCTION)
    swap_columns_default(TABLE, COLUMNS[:new], COLUMNS[:old])
    drop_constraint(TABLE, PRIMARY_KEY[:name], cascade: true)
    add_primary_key_using_index(TABLE, PRIMARY_KEY[:name], PRIMARY_KEY[:new_index][:name])
    INDEXES.each do |index_metadata|
      remove_index(TABLE, name: index_metadata[:old_name], if_exists: true) # rubocop:disable Migration/RemoveIndex -- remove the existing one before renaming
      rename_index(TABLE, index_metadata[:name], index_metadata[:old_name])
    end
  end

  def remove_integer_foreign_keys_and_rename_bigint
    (FOREIGN_KEYS + partitioned(P_FOREIGN_KEYS))
      .group_by { |fk_metadata| fk_metadata[:source_table] }
      .each do |_, fk_metadatas|
        with_lock_retries(raise_on_exhaustion: true) do
          fk_metadatas.each do |fk_metadata| # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- it's variable
            # If migration is re-run for a couple of times, the integer FK might have been removed in previous attempts
            # That means we should skip this block if integer FK does not exist.
            # Otherwise, this block will remove the renamed bigint FKs and break
            next unless foreign_key_exists?(
              fk_metadata[:source_table], TABLE, column: fk_metadata[:column], primary_key: :id
            )

            remove_foreign_key_if_exists(
              fk_metadata[:source_table], TABLE,
              column: fk_metadata[:column].first.to_s, primary_key: 'id', reverse_lock_order: true
            )

            if fk_metadata[:partitioned]
              rename_partitioned_foreign_key(fk_metadata[:source_table], tmp_name(fk_metadata), fk_metadata[:name])
            else
              rename_constraint(fk_metadata[:source_table], tmp_name(fk_metadata), fk_metadata[:name])
            end
          end
        end
      end
  end

  def remove_bigint_foreign_keys
    (FOREIGN_KEYS + P_FOREIGN_KEYS).each do |fk_metadata|
      with_lock_retries(raise_on_exhaustion: true) do
        remove_foreign_key_if_exists(
          fk_metadata[:source_table], TABLE,
          name: fk_metadata[:name], reverse_lock_order: true
        )
      end
    end
  end

  def recover_indexes
    [PRIMARY_KEY[:new_index]].concat(INDEXES).each do |index_metadata|
      add_concurrent_index(
        TABLE, index_metadata[:columns],
        name: index_metadata[:name], **index_metadata.fetch(:options, {})
      )
    end
  end

  def recover_all_foreign_keys
    FOREIGN_KEYS.each do |fk_metadata|
      add_concurrent_foreign_key(
        fk_metadata[:source_table], TABLE,
        **integer_options(fk_metadata.slice(:name, :column, :on_delete))
      )

      add_concurrent_foreign_key(
        fk_metadata[:source_table], TABLE,
        **bigint_options(fk_metadata.slice(:name, :column, :on_delete))
      )
    end

    P_FOREIGN_KEYS.each do |fk_metadata|
      add_concurrent_partitioned_foreign_key(
        fk_metadata[:source_table], TABLE,
        **integer_options(fk_metadata.slice(:name, :column, :on_delete))
      )

      add_concurrent_partitioned_foreign_key(
        fk_metadata[:source_table], TABLE,
        **bigint_options(fk_metadata.slice(:name, :column, :on_delete))
      )
    end
  end

  def integer_options(config_options)
    config_options.merge(target_column: [:id], reverse_lock_order: true, validate: true)
  end

  def bigint_options(config_options)
    config_options.merge(
      target_column: [:id_convert_to_bigint], reverse_lock_order: true, validate: true,
      name: tmp_name(config_options)
    )
  end

  def tmp_name(config_options)
    "#{config_options[:name]}_tmp"
  end

  def partitioned(fk_metadatas)
    fk_metadatas.map { |fk_metadata| fk_metadata.merge(partitioned: true) }
  end
end
