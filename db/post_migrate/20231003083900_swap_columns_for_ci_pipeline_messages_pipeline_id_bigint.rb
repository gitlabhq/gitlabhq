# frozen_string_literal: true

class SwapColumnsForCiPipelineMessagesPipelineIdBigint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :ci_pipeline_messages
  TARGET_TABLE_NAME = :ci_pipelines
  TRIGGER_FUNCTION_NAME = :trigger_bfad0e2b9c86
  COLUMN_NAME = :pipeline_id
  BIGINT_COLUMN_NAME = :pipeline_id_convert_to_bigint
  FK_NAME = :fk_rails_8d3b04e3e1
  BIGINT_FK_NAME = :fk_0946fea681
  INDEX_NAME = :index_ci_pipeline_messages_on_pipeline_id
  BIGINT_INDEX_NAME = :index_ci_pipeline_messages_on_pipeline_id_convert_to_bigint

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
      execute "LOCK TABLE #{TARGET_TABLE_NAME}, #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      # Rename the columns to swap names
      temp_name = "temp_#{COLUMN_NAME}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{COLUMN_NAME} TO #{temp_name}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{BIGINT_COLUMN_NAME} TO #{COLUMN_NAME}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{temp_name} TO #{BIGINT_COLUMN_NAME}"

      # Reset the trigger function
      execute "ALTER FUNCTION #{quote_column_name(TRIGGER_FUNCTION_NAME)} RESET ALL"

      # Swap the defaults
      change_column_default TABLE_NAME, COLUMN_NAME, nil
      change_column_default TABLE_NAME, BIGINT_COLUMN_NAME, 0

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
