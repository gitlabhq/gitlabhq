# frozen_string_literal: true

# Swaps the unique index for AlertManagement::HttpIntegration to include
# inactive integrations, making performance optimizations easier.
#
# At time of writing, gitlab.com has 0 records which would be invalidated
# by the new index. Of the ~1600 integrations, only ~100 are inactive, so the
# size of the index will not significantly change.
class ChangeAlertIntegrationsUniqueIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  UNIQUE_INDEX_NAME = 'index_http_integrations_on_project_and_endpoint'
  OLD_INDEX_NAME = 'index_http_integrations_on_active_and_project_and_endpoint'

  def up
    add_concurrent_index :alert_management_http_integrations,
      [:project_id, :endpoint_identifier],
      name: UNIQUE_INDEX_NAME,
      unique: true

    remove_concurrent_index_by_name :alert_management_http_integrations, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :alert_management_http_integrations,
      [:active, :project_id, :endpoint_identifier],
      unique: true,
      name: OLD_INDEX_NAME,
      where: 'active'

    remove_concurrent_index_by_name :alert_management_http_integrations, UNIQUE_INDEX_NAME
  end
end
