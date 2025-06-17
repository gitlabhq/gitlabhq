# frozen_string_literal: true

class SyncIndexRemovalForPCiBuildsTriggerRequestId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::IndexHelpers

  milestone '18.1'
  disable_ddl_transaction!

  TABLE = :p_ci_builds
  COLUMN = :trigger_request_id
  INDEX_NAME = :tmp_p_ci_builds_trigger_request_id_idx
  WHERE_CLAUSE = 'trigger_request_id IS NOT NULL'

  def up
    remove_concurrent_partitioned_index_by_name(TABLE, INDEX_NAME)
  end

  def down
    add_concurrent_partitioned_index(TABLE, COLUMN, name: INDEX_NAME, where: WHERE_CLAUSE)
  end
end
