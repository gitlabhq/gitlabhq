# frozen_string_literal: true

class MakeImportSyncRepositoriesProviderAgnostic < Gitlab::Database::Migration[2.3]
  milestone '19.5'
  disable_ddl_transaction!

  TABLE_NAME = :import_sync_repositories

  INSTALLATION_XID_CONSTRAINT = 'chk_import_sync_repositories_installation_xid'
  OLD_INSTALLATION_XID_CHECK = 'provider_installation_xid > 0'
  NEW_INSTALLATION_XID_CHECK = 'provider_installation_xid IS NULL OR provider_installation_xid > 0'

  # Widened with headroom beyond the 7 values in use today, so that adding a future
  # disconnect_reason doesn't need its own migration just to widen this constraint again.
  DISCONNECT_REASON_CONSTRAINT = 'chk_import_sync_repositories_disconnect_reason'
  OLD_DISCONNECT_REASON_CHECK = 'disconnect_reason IS NULL OR disconnect_reason BETWEEN 0 AND 3'
  NEW_DISCONNECT_REASON_CHECK = 'disconnect_reason IS NULL OR disconnect_reason BETWEEN 0 AND 9'

  def up
    change_column_null TABLE_NAME, :provider_installation_xid, true

    remove_check_constraint TABLE_NAME, INSTALLATION_XID_CONSTRAINT
    add_check_constraint TABLE_NAME, NEW_INSTALLATION_XID_CHECK, INSTALLATION_XID_CONSTRAINT

    remove_check_constraint TABLE_NAME, DISCONNECT_REASON_CONSTRAINT
    add_check_constraint TABLE_NAME, NEW_DISCONNECT_REASON_CHECK, DISCONNECT_REASON_CONSTRAINT
  end

  def down
    remove_check_constraint TABLE_NAME, DISCONNECT_REASON_CONSTRAINT
    add_check_constraint TABLE_NAME, OLD_DISCONNECT_REASON_CHECK, DISCONNECT_REASON_CONSTRAINT

    remove_check_constraint TABLE_NAME, INSTALLATION_XID_CONSTRAINT
    add_check_constraint TABLE_NAME, OLD_INSTALLATION_XID_CHECK, INSTALLATION_XID_CONSTRAINT

    change_column_null TABLE_NAME, :provider_installation_xid, false
  end
end
