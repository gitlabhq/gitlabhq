# frozen_string_literal: true

class AsyncValidateForeignKeyForCiSourcesPipelinesPipelineIdBigint < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_sources_pipelines
  COLUMN_NAME_MAPPINGS = {
    pipeline_id_convert_to_bigint: :fk_c1b5dc6b6f,
    source_pipeline_id_convert_to_bigint: :fk_1df371767f
  }

  def up
    COLUMN_NAME_MAPPINGS.each do |column_name, foreign_key_name|
      prepare_async_foreign_key_validation TABLE_NAME, column_name, name: foreign_key_name
    end
  end

  def down
    COLUMN_NAME_MAPPINGS.each do |column_name, foreign_key_name|
      unprepare_async_foreign_key_validation TABLE_NAME, column_name, name: foreign_key_name
    end
  end
end
