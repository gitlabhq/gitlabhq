# frozen_string_literal: true

class AddUserPreferenceToTurnOffAutomaticLists < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    add_column :user_preferences, :markdown_automatic_lists, :boolean, default: true, null: false
  end

  def down
    remove_column :user_preferences, :markdown_automatic_lists, :boolean
  end
end
