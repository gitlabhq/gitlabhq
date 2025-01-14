# frozen_string_literal: true

class SyncIndexForPCiPipelinesTriggerId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.8'
  disable_ddl_transaction!

  TABLE = :p_ci_pipelines
  COLUMN = :trigger_id
  INDEX_NAME = :p_ci_pipelines_trigger_id_idx

  def up
    add_concurrent_partitioned_index(TABLE, COLUMN, name: INDEX_NAME)
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE, INDEX_NAME)
  end
end
