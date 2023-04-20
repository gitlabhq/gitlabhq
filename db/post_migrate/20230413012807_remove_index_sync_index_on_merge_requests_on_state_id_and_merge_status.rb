# frozen_string_literal: true

class RemoveIndexSyncIndexOnMergeRequestsOnStateIdAndMergeStatus < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :merge_requests, name: 'idx_merge_requests_on_state_id_and_merge_status'
  end

  def down
    add_concurrent_index :merge_requests, [:state_id, :merge_status],
      where: "((state_id = 1) AND ((merge_status)::text = 'can_be_merged'::text))",
      name: 'idx_merge_requests_on_state_id_and_merge_status'
  end
end
