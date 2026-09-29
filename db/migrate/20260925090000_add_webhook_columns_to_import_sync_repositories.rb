# frozen_string_literal: true

class AddWebhookColumnsToImportSyncRepositories < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    add_column :import_sync_repositories, :provider_webhook_xid, :bigint
    add_column :import_sync_repositories, :webhook_secret, :jsonb
  end
end
