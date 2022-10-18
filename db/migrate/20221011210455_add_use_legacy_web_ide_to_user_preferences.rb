# frozen_string_literal: true

class AddUseLegacyWebIdeToUserPreferences < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :user_preferences, :use_legacy_web_ide, :boolean, default: false, null: false
  end
end
