# frozen_string_literal: true

class AddIndexJiraConnectInstallationsOnOrgIdCloudId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  INDEX_NAME = 'index_jira_connect_installations_on_org_id_cloud_id'

  def up
    # Non-unique: There can be Jira sites mapping to multiple installation
    # rows under the default org (stale rows from re-installs), so (organization_id,
    # cloud_id) is not unique. The index only backs the FIT cloud_id lookup.
    add_concurrent_index :jira_connect_installations, [:organization_id, :cloud_id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :jira_connect_installations, INDEX_NAME
  end
end
