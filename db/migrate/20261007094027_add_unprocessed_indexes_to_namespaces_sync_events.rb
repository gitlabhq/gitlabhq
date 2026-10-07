# frozen_string_literal: true

class AddUnprocessedIndexesToNamespacesSyncEvents < Gitlab::Database::Migration[2.3]
  milestone '19.5'
  disable_ddl_transaction!

  TABLE = :namespaces_sync_events
  CI_INDEX = 'index_namespaces_sync_events_on_id_where_not_ci_synced'
  SEC_INDEX = 'index_namespaces_sync_events_on_id_where_not_sec_synced'

  def up
    add_concurrent_index TABLE, :id, where: 'ci_synced = false', name: CI_INDEX
    add_concurrent_index TABLE, :id, where: 'sec_synced = false', name: SEC_INDEX
  end

  def down
    remove_concurrent_index_by_name TABLE, CI_INDEX
    remove_concurrent_index_by_name TABLE, SEC_INDEX
  end
end
