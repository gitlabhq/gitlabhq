# frozen_string_literal: true

class AddIndexToMergeTrainsOnUpdatedAtForMerging < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  TABLE_NAME = :merge_trains
  INDEX_NAME = 'index_merge_trains_on_updated_at_when_merging'
  # MergeTrains::Car state_machine: state :merging, value: 4
  WHERE_CLAUSE = 'status = 4'

  def up
    add_concurrent_index TABLE_NAME, [:updated_at, :id], where: WHERE_CLAUSE, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
