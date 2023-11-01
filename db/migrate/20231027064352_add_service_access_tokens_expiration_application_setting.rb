# frozen_string_literal: true

class AddServiceAccessTokensExpirationApplicationSetting < Gitlab::Database::Migration[2.2]
  milestone '16.6'

  enable_lock_retries!

  def change
    add_column :application_settings, :service_access_tokens_expiration_enforced, :boolean, default: true, null: false
  end
end
