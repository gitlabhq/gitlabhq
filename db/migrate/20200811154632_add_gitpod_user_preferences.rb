# frozen_string_literal: true

class AddGitpodUserPreferences < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :user_preferences, :gitpod_enabled, :boolean, default: false, null: false
  end
end
