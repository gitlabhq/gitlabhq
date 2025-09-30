# frozen_string_literal: true

class RemoveJiraConnectInstallationsTempIndex < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_idx_jira_connect_installations_on_id_organization_id'

  def up
    remove_concurrent_index_by_name :jira_connect_installations, INDEX_NAME
  end

  def down
    add_concurrent_index(
      :jira_connect_installations,
      :id,
      where: 'organization_id IS NULL',
      name: INDEX_NAME
    )
  end
end
