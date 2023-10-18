# frozen_string_literal: true

class SwapColumnsForCiStagesPipelineIdBigint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :ci_stages
  TARGET_TABLE_NAME = :ci_pipelines
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

      # Swap fkey constraint
      temp_fk_name = "temp_#{FK_NAME}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME CONSTRAINT #{FK_NAME} TO #{temp_fk_name}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME CONSTRAINT #{BIGINT_FK_NAME} TO #{FK_NAME}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME CONSTRAINT #{temp_fk_name} TO #{BIGINT_FK_NAME}"

      # Swap index
      INDEX_NAMES.each_with_index do |index_name, i|
        bigint_index_name = BIGINT_INDEX_NAMES[i]
        temp_index_name = "temp_#{index_name}"

        execute "ALTER INDEX #{index_name} RENAME TO #{temp_index_name}"
        execute "ALTER INDEX #{bigint_index_name} RENAME TO #{index_name}"
        execute "ALTER INDEX #{temp_index_name} RENAME TO #{bigint_index_name}"
      end
    end
  end
end
