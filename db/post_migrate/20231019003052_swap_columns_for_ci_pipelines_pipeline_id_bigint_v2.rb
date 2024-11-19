# frozen_string_literal: true

class SwapColumnsForCiPipelinesPipelineIdBigintV2 < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum
  include Gitlab::Database::MigrationHelpers::Swapping

  disable_ddl_transaction!

  TABLE_NAME = :ci_pipelines
  TRIGGER_FUNCTION_NAME = :trigger_1bd97da9c1a4
  COLUMN_NAME = :auto_canceled_by_id
  BIGINT_COLUMN_NAME = :auto_canceled_by_id_convert_to_bigint
  FK_NAME = :fk_262d4c2d19
  BIGINT_FK_NAME = :fk_67e4288f3a
  INDEX_NAME = :index_ci_pipelines_on_auto_canceled_by_id
  BIGINT_INDEX_NAME = :index_ci_pipelines_on_auto_canceled_by_id_bigint

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
    !can_execute_on?(TABLE_NAME)
  end

  def column_type_of?(type)
    column_for(TABLE_NAME, COLUMN_NAME).sql_type.to_s == type.to_s
  end

  def swap
    with_lock_retries(raise_on_exhaustion: true) do
      # Lock the tables involved.
      lock_tables(TABLE_NAME)

      # Rename the columns to swap names
      swap_columns(TABLE_NAME, COLUMN_NAME, BIGINT_COLUMN_NAME)

      # Reset the trigger function
      reset_trigger_function(TRIGGER_FUNCTION_NAME)

      # Swap fkey constraint
      swap_foreign_keys(TABLE_NAME, FK_NAME, BIGINT_FK_NAME)

      # Swap index
      swap_indexes(TABLE_NAME, INDEX_NAME, BIGINT_INDEX_NAME)
    end
  end
end
