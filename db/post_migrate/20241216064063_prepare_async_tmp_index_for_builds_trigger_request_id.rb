# frozen_string_literal: true

class PrepareAsyncTmpIndexForBuildsTriggerRequestId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.8'

  TABLE = :p_ci_builds
  COLUMN = :trigger_request_id
  INDEX_NAME = :tmp_p_ci_builds_trigger_request_id_idx
  WHERE = 'trigger_request_id IS NOT NULL'

  def up
    prepare_partitioned_async_index(TABLE, COLUMN, name: INDEX_NAME, where: WHERE)
  end

  def down
    unprepare_partitioned_async_index(TABLE, COLUMN, name: INDEX_NAME)
  end
end
