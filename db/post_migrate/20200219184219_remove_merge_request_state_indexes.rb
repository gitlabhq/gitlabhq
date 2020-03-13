# frozen_string_literal: true

class RemoveMergeRequestStateIndexes < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # merge_requests state column is ignored since 12.6 and will be removed on a following migration
  def up
    remove_concurrent_index_by_name :merge_requests, 'index_merge_requests_on_id_and_merge_jid'
    remove_concurrent_index_by_name :merge_requests, 'index_merge_requests_on_source_project_and_branch_state_opened'
    remove_concurrent_index_by_name :merge_requests, 'index_merge_requests_on_state_and_merge_status'
    remove_concurrent_index_by_name :merge_requests, 'index_merge_requests_on_target_project_id_and_iid_opened'
  end

  def down
    add_concurrent_index :merge_requests,
                         [:id, :merge_jid],
                         where: "merge_jid IS NOT NULL and state = 'locked'",
                         name: 'index_merge_requests_on_id_and_merge_jid'

    add_concurrent_index :merge_requests,
                         [:source_project_id, :source_branch],
                         where: "state = 'opened'",
                         name: 'index_merge_requests_on_source_project_and_branch_state_opened'

    add_concurrent_index :merge_requests,
                         [:state, :merge_status],
                         where: "state = 'opened' AND merge_status = 'can_be_merged'",
                         name: 'index_merge_requests_on_state_and_merge_status'

    add_concurrent_index :merge_requests,
                         [:target_project_id, :iid],
                         where: "state = 'opened'",
                         name: 'index_merge_requests_on_target_project_id_and_iid_opened'
  end
end
