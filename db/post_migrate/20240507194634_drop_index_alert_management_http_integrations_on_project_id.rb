# frozen_string_literal: true

class DropIndexAlertManagementHttpIntegrationsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  disable_ddl_transaction!

  TABLE_NAME = :alert_management_http_integrations
  INDEX_NAME = :index_alert_management_http_integrations_on_project_id
  COLUMN_NAMES = [:project_id]

  def up
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
  end
end
