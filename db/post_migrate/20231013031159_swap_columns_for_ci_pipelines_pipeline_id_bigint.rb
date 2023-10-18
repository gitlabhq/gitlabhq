# frozen_string_literal: true

class SwapColumnsForCiPipelinesPipelineIdBigint < Gitlab::Database::Migration[2.1]
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
    swap
  end

  def down
    swap
  end

  private

  def swap
    with_lock_retries(raise_on_exhaustion: true) do
      # Lock the tables involved.
      execute "LOCK TABLE #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      # Rename the columns to swap names
      temp_name = "temp_#{COLUMN_NAME}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{COLUMN_NAME} TO #{temp_name}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{BIGINT_COLUMN_NAME} TO #{COLUMN_NAME}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{temp_name} TO #{BIGINT_COLUMN_NAME}"

      # Reset the trigger function
      execute "ALTER FUNCTION #{quote_column_name(TRIGGER_FUNCTION_NAME)} RESET ALL"

      # Swap fkey constraint
      temp_fk_name = "temp_#{FK_NAME}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME CONSTRAINT #{FK_NAME} TO #{temp_fk_name}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME CONSTRAINT #{BIGINT_FK_NAME} TO #{FK_NAME}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME CONSTRAINT #{temp_fk_name} TO #{BIGINT_FK_NAME}"

      # Swap index
      temp_index_name = "temp_#{INDEX_NAME}"

      execute "ALTER INDEX #{INDEX_NAME} RENAME TO #{temp_index_name}"
      execute "ALTER INDEX #{BIGINT_INDEX_NAME} RENAME TO #{INDEX_NAME}"
      execute "ALTER INDEX #{temp_index_name} RENAME TO #{BIGINT_INDEX_NAME}"
    end
  end
end
