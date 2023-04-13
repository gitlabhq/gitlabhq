# frozen_string_literal: true

class AddIdentityToggleToUserPreferences < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :user_preferences, :pass_user_identities_to_ci_jwt, :boolean, default: false, null: false
  end
end
