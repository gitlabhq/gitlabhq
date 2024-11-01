# frozen_string_literal: true

class SwapColumnsForCiStagesPipelineIdBigintV2 < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum
  include Gitlab::Database::MigrationHelpers::Swapping

  disable_ddl_transaction!

  TABLE_NAME = :ci_stages
  TRIGGER_FUNCTION_NAME = :trigger_07bc3c48f407
  COLUMN_NAME = :pipeline_id
  BIGINT_COLUMN_NAME = :pipeline_id_convert_to_bigint
  FK_NAME = :fk_fb57e6cc56
  BIGINT_FK_NAME = :fk_c5ddde695f
  INDEX_NAMES = %i[
    index_ci_stages_on_pipeline_id
    index_ci_stages_on_pipeline_id_and_id
    index_ci_stages_on_pipeline_id_and_name
    index_ci_stages_on_pipeline_id_and_position
  ]
  BIGINT_INDEX_NAMES = %i[
    index_ci_stages_on_pipeline_id_convert_to_bigint
    index_ci_stages_on_pipeline_id_convert_to_bigint_and_id
    index_ci_stages_on_pipeline_id_convert_to_bigint_and_name
    index_ci_stages_on_pipeline_id_convert_to_bigint_and_position
  ]

  def up
    return if should_skip? || column_type_of?(:bigint)

    swap
  end

  def down
    return if should_skip? || column_type_of?(:integer)

    swap
  end

  private

  def should_skip?
    !can_execute_on?(:ci_pipelines, :ci_stages)
  end

  def column_type_of?(type)
    column_for(TABLE_NAME, COLUMN_NAME).sql_type.to_s == type.to_s
  end

  def swap
    with_lock_retries(raise_on_exhaustion: true) do
      # Lock the tables involved.
      lock_tables(:ci_pipelines, :ci_stages)

      # Rename the columns to swap names
      swap_columns(TABLE_NAME, COLUMN_NAME, BIGINT_COLUMN_NAME)

      # Reset the trigger function
      reset_trigger_function(TRIGGER_FUNCTION_NAME)

      # Swap fkey constraint
      swap_foreign_keys(TABLE_NAME, FK_NAME, BIGINT_FK_NAME)

      # Swap index
      INDEX_NAMES.each_with_index do |index_name, i|
        swap_indexes(TABLE_NAME, index_name, BIGINT_INDEX_NAMES[i])
      end
    end
  end
end
