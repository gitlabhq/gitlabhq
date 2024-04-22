# frozen_string_literal: true

class ValidateFkIdBigint4CiPipelinesPCiBuildsCiPipelinesConfigPCiStages < Gitlab::Database::Migration[2.2]
  include ::Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.0'
  disable_ddl_transaction!

  TABLE = :ci_pipelines
  FOREIGN_KEYS = [
    {
      source_table: :ci_pipelines,
      options: {
        name: :fk_262d4c2d19_tmp,
        column: [:auto_canceled_by_id],
        on_delete: :nullify
      }
    },
    {
      source_table: :ci_pipeline_chat_data,
      options: {
        name: :fk_64ebfab6b3_tmp,
        column: [:pipeline_id],
        on_delete: :cascade
      }
    },
    {
      source_table: :ci_sources_pipelines,
      options: {
        name: :fk_d4e29af7d7_tmp,
        column: [:source_pipeline_id],
        on_delete: :cascade
      }
    },
    {
      source_table: :ci_sources_pipelines,
      options: {
        name: :fk_e1bad85861_tmp,
        column: [:pipeline_id],
        on_delete: :cascade
      }
    },
    {
      source_table: :ci_sources_projects,
      options: {
        name: :fk_rails_10a1eb379a_tmp,
        column: [:pipeline_id],
        on_delete: :cascade
      }
    },
    {
      source_table: :ci_pipeline_metadata,
      options: {
        name: :fk_rails_50c1e9ea10_tmp,
        column: [:pipeline_id],
        on_delete: :cascade
      }
    },
    {
      source_table: :ci_pipeline_messages,
      options: {
        name: :fk_rails_8d3b04e3e1_tmp,
        column: [:pipeline_id],
        on_delete: :cascade
      }
    },
    {
      source_table: :ci_pipelines_config,
      options: {
        name: :fk_rails_906c9a2533_tmp,
        column: [:pipeline_id],
        on_delete: :cascade
      }
    },
    {
      source_table: :ci_pipeline_artifacts,
      options: {
        name: :fk_rails_a9e811a466_tmp,
        column: [:pipeline_id],
        on_delete: :cascade
      }
    },
    {
      source_table: :ci_daily_build_group_report_results,
      options: {
        name: :fk_rails_ee072d13b3_tmp,
        column: [:last_pipeline_id],
        on_delete: :cascade
      }
    }
  ]

  P_FOREIGN_KEYS = [
    {
      source_table: :p_ci_builds,
      options: {
        name: :fk_87f4cefcda_tmp,
        column: [:upstream_pipeline_id],
        on_delete: :cascade
      }
    },
    {
      source_table: :p_ci_builds,
      options: {
        name: :fk_d3130c9a7f_tmp,
        column: [:commit_id],
        on_delete: :cascade
      }
    },
    {
      source_table: :p_ci_builds,
      options: {
        name: :fk_a2141b1522_tmp,
        column: [:auto_canceled_by_id],
        on_delete: :nullify
      }
    },
    {
      source_table: :p_ci_pipeline_variables,
      options: {
        name: :fk_f29c5f4380_tmp,
        column: [:pipeline_id],
        on_delete: :cascade
      }
    },
    {
      source_table: :p_ci_stages,
      options: {
        name: :fk_fb57e6cc56_tmp,
        column: [:pipeline_id],
        on_delete: :cascade
      }
    }
  ]

  def up
    FOREIGN_KEYS.each do |fk|
      validate_foreign_key(fk[:source_table], fk[:options][:column], name: fk[:options][:name])
    end

    P_FOREIGN_KEYS.each do |fk|
      add_concurrent_partitioned_foreign_key(fk[:source_table], TABLE, **default_options.merge(fk[:options]))
    end
  end

  def down
    FOREIGN_KEYS.each do |fk|
      with_lock_retries do
        remove_foreign_key_if_exists(
          fk[:source_table], TABLE,
          name: fk[:options][:name], reverse_lock_order: true
        )
      end

      add_concurrent_foreign_key(fk[:source_table], TABLE, **default_options.merge(fk[:options]), validate: false)
    end

    P_FOREIGN_KEYS.each do |fk|
      with_lock_retries do
        remove_foreign_key_if_exists(
          fk[:source_table], TABLE,
          name: fk[:options][:name], reverse_lock_order: true
        )
      end

      add_concurrent_partitioned_foreign_key(
        fk[:source_table], TABLE, **default_options.merge(fk[:options]), validate: false
      )
    end
  end

  private

  def default_options
    { target_column: [:id_convert_to_bigint], reverse_lock_order: true, validate: true }
  end
end
