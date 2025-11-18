# frozen_string_literal: true

class AddJiraTrackerDataIndexOnIdProjectIdOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_idx_jira_tracker_data_on_id_project_id_organization_id'

  def up
    add_concurrent_index(
      :jira_tracker_data,
      :id,
      where: 'project_id IS NOT NULL AND organization_id IS NOT NULL',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name :jira_tracker_data, INDEX_NAME
  end
end
