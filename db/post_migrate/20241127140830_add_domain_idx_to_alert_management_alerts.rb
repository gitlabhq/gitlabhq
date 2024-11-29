# frozen_string_literal: true

class AddDomainIdxToAlertManagementAlerts < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  INDEX_NAME = 'index_alerts_on_project_id_domain_status'

  disable_ddl_transaction!

  def up
    add_concurrent_index :alert_management_alerts, %i[project_id domain status], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :alert_management_alerts, INDEX_NAME
  end
end
