class AddMergeRequestStateIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests, [:source_project_id, :source_branch],
                         where: "state = 'opened'",
                         name: 'index_merge_requests_on_source_project_and_branch_state_opened'
  end

  def down
    remove_concurrent_index_by_name :merge_requests,
                                    'index_merge_requests_on_source_project_and_branch_state_opened'
  end
end
