# frozen_string_literal: true

class AddDpopEnabledToUserPreferences < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column :user_preferences, :dpop_enabled, :boolean, default: false, null: false, if_not_exists: true
  end
end
