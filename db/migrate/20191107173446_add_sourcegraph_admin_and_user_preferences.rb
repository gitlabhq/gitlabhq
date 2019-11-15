# frozen_string_literal: true

class AddSourcegraphAdminAndUserPreferences < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column(:application_settings, :sourcegraph_public_only, :boolean, default: true, null: false)
    add_column(:user_preferences, :sourcegraph_enabled, :boolean)
  end

  def down
    remove_column(:application_settings, :sourcegraph_public_only)
    remove_column(:user_preferences, :sourcegraph_enabled)
  end
end
