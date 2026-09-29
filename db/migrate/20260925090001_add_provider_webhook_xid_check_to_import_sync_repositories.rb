# frozen_string_literal: true

class AddProviderWebhookXidCheckToImportSyncRepositories < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.5'

  CONSTRAINT_NAME = 'chk_import_sync_repositories_webhook_xid'

  def up
    add_check_constraint :import_sync_repositories,
      'provider_webhook_xid IS NULL OR provider_webhook_xid > 0',
      CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :import_sync_repositories, CONSTRAINT_NAME
  end
end
