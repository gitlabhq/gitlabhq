# frozen_string_literal: true

class SwapColumnsForCiPipelineVariablesPipelineIdBigint < Gitlab::Database::Migration[2.1]
  include ::Gitlab::Database::MigrationHelpers::Swapping
  disable_ddl_transaction!

  def up
    swap
  end

  def down
    swap
  end

  private

  def swap
    with_lock_retries(raise_on_exhaustion: true) do
      lock_tables(:ci_pipelines, :ci_pipeline_variables)

      swap_columns(
        :ci_pipeline_variables,
        :pipeline_id,
        :pipeline_id_convert_to_bigint
      )
      reset_trigger_function(:trigger_7f3d66a7d7f5)
      swap_columns_default(
        :ci_pipeline_variables,
        :pipeline_id,
        :pipeline_id_convert_to_bigint
      )
      swap_foreign_keys(
        :ci_pipeline_variables,
        :fk_f29c5f4380,
        :temp_fk_rails_8d3b04e3e1
      )
      swap_indexes(
        :ci_pipeline_variables,
        :index_ci_pipeline_variables_on_pipeline_id_and_key,
        :index_ci_pipeline_variables_on_pipeline_id_bigint_and_key
      )
    end
  end
end
