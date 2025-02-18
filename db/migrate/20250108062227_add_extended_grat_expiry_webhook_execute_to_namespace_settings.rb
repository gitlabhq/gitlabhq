# frozen_string_literal: true

class AddExtendedGratExpiryWebhookExecuteToNamespaceSettings < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '17.9'

  def change
    add_column :namespace_settings, :extended_grat_expiry_webhooks_execute, :boolean, default: false, null: false
  end
end
