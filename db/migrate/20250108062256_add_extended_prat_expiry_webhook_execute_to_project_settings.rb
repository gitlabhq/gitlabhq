# frozen_string_literal: true

class AddExtendedPratExpiryWebhookExecuteToProjectSettings < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '17.9'

  def change
    add_column :project_settings, :extended_prat_expiry_webhooks_execute, :boolean, default: false, null: false
  end
end
