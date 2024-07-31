# frozen_string_literal: true

class AddRequirePatExpiryToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :application_settings, :require_personal_access_token_expiry, :boolean, default: true, null: false
  end
end
