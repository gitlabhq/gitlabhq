# frozen_string_literal: true

class SyncTmpIndexForPCiBuildsTriggerRequestId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.8'
  disable_ddl_transaction!

  TABLE = :p_ci_builds
  COLUMN = :trigger_request_id
  INDEX_NAME = :tmp_p_ci_builds_trigger_request_id_idx
  WHERE = 'trigger_request_id IS NOT NULL'

  def up
    add_concurrent_partitioned_index(TABLE, COLUMN, name: INDEX_NAME, where: WHERE)
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE, INDEX_NAME)
  end
end
