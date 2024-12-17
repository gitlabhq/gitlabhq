# frozen_string_literal: true

class AddIndexMergeRequestsOnUnmergedStateId < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  disable_ddl_transaction!

  INDEX_NAME = :idx_merge_requests_on_unmerged_state_id
  TABLE_NAME = :merge_requests

  def up
    # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
    add_concurrent_index(TABLE_NAME, :id, name: INDEX_NAME, where: "state_id <> 3")
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
