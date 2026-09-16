# frozen_string_literal: true

class AddPipelineFkToPCiPipelineProcessingData < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.5'
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :p_ci_pipeline_processing_data
  TARGET_TABLE_NAME = :p_ci_pipelines
  COLUMN = [:partition_id, :pipeline_id]
  TARGET_COLUMN = [:partition_id, :id]

  def up
    add_concurrent_partitioned_foreign_key(
      SOURCE_TABLE_NAME, TARGET_TABLE_NAME,
      column: COLUMN,
      target_column: TARGET_COLUMN,
      on_update: :cascade,
      on_delete: :cascade
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists SOURCE_TABLE_NAME, TARGET_TABLE_NAME, column: COLUMN
    end
  end
end
