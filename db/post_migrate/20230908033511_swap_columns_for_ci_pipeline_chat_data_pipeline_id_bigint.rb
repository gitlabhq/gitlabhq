# frozen_string_literal: true

class SwapColumnsForCiPipelineChatDataPipelineIdBigint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :ci_pipeline_chat_data
  TARGET_TABLE_NAME = :ci_pipelines
  TRIGGER_FUNCTION_NAME = :trigger_239c8032a8d6
  COLUMN_NAME = :pipeline_id
  BIGINT_COLUMN_NAME = :pipeline_id_convert_to_bigint
  LEGACY_FK_NAME = :fk_rails_64ebfab6b3
  FK_NAME = :fk_64ebfab6b3
  BIGINT_FK_NAME = :fk_5b21bde562

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
      rename_column TABLE_NAME, COLUMN_NAME, temp_name # rubocop:disable Migration/WithLockRetriesDisallowedMethod
      rename_column TABLE_NAME, BIGINT_COLUMN_NAME, COLUMN_NAME # rubocop:disable Migration/WithLockRetriesDisallowedMethod
      rename_column TABLE_NAME, temp_name, BIGINT_COLUMN_NAME # rubocop:disable Migration/WithLockRetriesDisallowedMethod

      # Reset the trigger function
      execute "ALTER FUNCTION #{quote_column_name(TRIGGER_FUNCTION_NAME)} RESET ALL"

      # Swap the defaults
      change_column_default TABLE_NAME, COLUMN_NAME, nil
      change_column_default TABLE_NAME, BIGINT_COLUMN_NAME, 0

      # Swap fkey constraint
      if foreign_key_exists?(TABLE_NAME, name: LEGACY_FK_NAME)
        execute "ALTER TABLE #{TABLE_NAME} RENAME CONSTRAINT #{LEGACY_FK_NAME} TO #{FK_NAME}"
      end

      temp_fk_name = "temp_#{FK_NAME}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME CONSTRAINT #{FK_NAME} TO #{temp_fk_name}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME CONSTRAINT #{BIGINT_FK_NAME} TO #{FK_NAME}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME CONSTRAINT #{temp_fk_name} TO #{BIGINT_FK_NAME}"
    end
  end
end
