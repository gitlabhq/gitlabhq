# frozen_string_literal: true

class AddWebhookDeliveriesCheckedAtToImportSyncRepositories < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  def change
    add_column :import_sync_repositories, :webhook_deliveries_checked_at, :datetime_with_timezone
  end
end
