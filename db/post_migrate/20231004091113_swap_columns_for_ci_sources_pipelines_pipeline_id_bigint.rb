# frozen_string_literal: true

class SwapColumnsForCiSourcesPipelinesPipelineIdBigint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :ci_sources_pipelines
  TARGET_TABLE_NAME = :ci_pipelines
  TRIGGER_FUNCTION_NAME = :trigger_68d7b6653c7d
  COLUMN_NAMES = %i[pipeline_id source_pipeline_id]
  BIGINT_COLUMN_NAMES = %i[pipeline_id_convert_to_bigint source_pipeline_id_convert_to_bigint]
  FK_NAMES = [
    :fk_e1bad85861, # for pipeline_id
    :fk_d4e29af7d7 # for source_pipeline_id
  ]
  BIGINT_FK_NAMES = [
    :fk_c1b5dc6b6f, # for pipeline_id_convert_to_bigint
    :fk_1df371767f # for source_pipeline_id_convert_to_bigint
  ]
  INDEX_NAMES = %i[
    index_ci_sources_pipelines_on_pipeline_id
    index_ci_sources_pipelines_on_source_pipeline_id
  ]
  BIGINT_INDEX_NAMES = %i[
    index_ci_sources_pipelines_on_pipeline_id_bigint
    index_ci_sources_pipelines_on_source_pipeline_id_bigint
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
      COLUMN_NAMES.each_with_index do |column_name, i|
        bigint_column_name = BIGINT_COLUMN_NAMES[i]
        temp_name = "temp_#{column_name}"

        execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{column_name} TO #{temp_name}"
        execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{bigint_column_name} TO #{column_name}"
        execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{temp_name} TO #{bigint_column_name}"
      end

      # Reset the trigger function
      execute "ALTER FUNCTION #{quote_column_name(TRIGGER_FUNCTION_NAME)} RESET ALL"

      # Swap fkey constraint
      FK_NAMES.each_with_index do |fk_name, i|
        bigint_fk_name = BIGINT_FK_NAMES[i]
        temp_fk_name = "temp_#{fk_name}"

        execute "ALTER TABLE #{TABLE_NAME} RENAME CONSTRAINT #{fk_name} TO #{temp_fk_name}"
        execute "ALTER TABLE #{TABLE_NAME} RENAME CONSTRAINT #{bigint_fk_name} TO #{fk_name}"
        execute "ALTER TABLE #{TABLE_NAME} RENAME CONSTRAINT #{temp_fk_name} TO #{bigint_fk_name}"
      end

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
