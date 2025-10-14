# frozen_string_literal: true

class AddIssueTrackerDataIndexOnIdGroupIdOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_idx_issue_tracker_data_on_id_group_id_organization_id'

  def up
    add_concurrent_index(
      :issue_tracker_data,
      :id,
      where: 'group_id IS NOT NULL AND organization_id IS NOT NULL',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name :issue_tracker_data, INDEX_NAME
  end
end
