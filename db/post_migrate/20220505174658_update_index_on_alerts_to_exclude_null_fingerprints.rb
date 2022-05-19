# frozen_string_literal: true

class UpdateIndexOnAlertsToExcludeNullFingerprints < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_partial_am_alerts_on_project_id_and_fingerprint'
  NEW_INDEX_NAME = 'index_unresolved_alerts_on_project_id_and_fingerprint'

  def up
    add_concurrent_index :alert_management_alerts,
      [:project_id, :fingerprint],
      where: "fingerprint IS NOT NULL and status <> 2",
      name: NEW_INDEX_NAME,
      unique: true

    remove_concurrent_index_by_name :alert_management_alerts, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :alert_management_alerts,
      [:project_id, :fingerprint],
      where: "status <> 2",
      name: OLD_INDEX_NAME,
      unique: true

    remove_concurrent_index_by_name :alert_management_alerts, NEW_INDEX_NAME
  end
end
