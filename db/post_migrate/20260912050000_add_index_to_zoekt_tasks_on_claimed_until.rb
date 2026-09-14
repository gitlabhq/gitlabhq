# frozen_string_literal: true

class AddIndexToZoektTasksOnClaimedUntil < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.4'
  disable_ddl_transaction!

  TABLE_NAME = :zoekt_tasks
  INDEX_NAME = :index_zoekt_tasks_on_claimed_until_for_processing
  # 1 is Search::Zoekt::Taskable's `processing` state; the sweep only ever reads
  # that state, so the index stays the size of the in-flight set.
  WHERE_CLAUSE = 'state = 1'

  def up
    add_concurrent_partitioned_index TABLE_NAME, :claimed_until, where: WHERE_CLAUSE, name: INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name TABLE_NAME, INDEX_NAME
  end
end
