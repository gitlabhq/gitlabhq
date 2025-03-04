# frozen_string_literal: true

class IndexResourceMilestoneEventsIssueMergeRequestMissing < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'tmp_idx_resource_milestone_events_issue_mr_missing'

  disable_ddl_transaction!
  milestone '17.10'

  def up
    add_concurrent_index :resource_milestone_events,
      :id,
      name: INDEX_NAME,
      where: 'issue_id IS NULL AND merge_request_id IS NULL'
  end

  def down
    remove_concurrent_index :resource_milestone_events, :id, name: INDEX_NAME
  end
end
