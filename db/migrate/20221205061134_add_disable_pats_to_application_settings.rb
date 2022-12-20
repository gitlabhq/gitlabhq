# frozen_string_literal: true

class AddDisablePatsToApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column(:application_settings, :disable_personal_access_tokens, :boolean, default: false, null: false)
  end
end
