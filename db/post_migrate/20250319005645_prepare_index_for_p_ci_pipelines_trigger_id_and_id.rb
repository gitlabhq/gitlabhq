# frozen_string_literal: true

class PrepareIndexForPCiPipelinesTriggerIdAndId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.11'

  TABLE_NAME = :p_ci_pipelines
  COLUMN_NAMES = [:trigger_id, :id]
  INDEX_NAME = :p_ci_pipelines_trigger_id_id_desc_idx
  INDEX_ORDER = { id: :desc }

  def up
    prepare_partitioned_async_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME, order: INDEX_ORDER)
  end

  def down
    unprepare_partitioned_async_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
  end
end
