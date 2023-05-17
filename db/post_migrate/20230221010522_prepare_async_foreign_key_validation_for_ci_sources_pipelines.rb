# frozen_string_literal: true

class PrepareAsyncForeignKeyValidationForCiSourcesPipelines < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_sources_pipelines
  COLUMN_NAMES = [:source_partition_id, :source_job_id]
  FOREIGN_KEY_NAME = :fk_be5624bf37_p

  def up
    prepare_async_foreign_key_validation(TABLE_NAME, COLUMN_NAMES, name: FOREIGN_KEY_NAME)
  end

  def down
    unprepare_async_foreign_key_validation(TABLE_NAME, COLUMN_NAMES, name: FOREIGN_KEY_NAME)
  end
end
