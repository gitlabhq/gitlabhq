# frozen_string_literal: true

class PrepareAsyncIndexForPCiPipelinesTriggerId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.7'

  TABLE = :p_ci_pipelines
  COLUMN = :trigger_id
  INDEX_NAME = :p_ci_pipelines_trigger_id_idx

  def up
    prepare_partitioned_async_index(TABLE, COLUMN, name: INDEX_NAME)
  end

  def down
    unprepare_partitioned_async_index(TABLE, COLUMN, name: INDEX_NAME)
  end
end
