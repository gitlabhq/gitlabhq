# frozen_string_literal: true

class SwapColumnsForCiPipelinesPipelineIdBigintForSelfHost < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::Swapping

  milestone '16.6'
  disable_ddl_transaction!

  TABLE_NAME = :ci_pipelines
  TRIGGER_FUNCTION_NAME = :trigger_1bd97da9c1a4
  COLUMN_NAME = :auto_canceled_by_id
  BIGINT_COLUMN_NAME = :auto_canceled_by_id_convert_to_bigint
  INDEX_NAME = :index_ci_pipelines_on_auto_canceled_by_id
  BIGINT_INDEX_NAME = :index_ci_pipelines_on_auto_canceled_by_id_bigint

  class PgForeignKeys < MigrationRecord
    self.table_name = :postgres_foreign_keys
  end

  def up
    return if column_type_of?(:bigint)

    swap
  end

  def down
    return if column_type_of?(:integer)

    swap
  end

  private

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
      swap_foreign_keys(
        TABLE_NAME,
        foreign_key_name_for(TABLE_NAME, COLUMN_NAME),
        foreign_key_name_for(TABLE_NAME, BIGINT_COLUMN_NAME)
      )

      # Swap index
      swap_indexes(TABLE_NAME, INDEX_NAME, BIGINT_INDEX_NAME)
    end
  end

  def foreign_key_name_for(source, column)
    PgForeignKeys
      .where(constrained_table_name: source)
      .where(constrained_columns: [column])
      .first&.name || raise("Required foreign key for #{source} #{column} is missing.")
  end
end
