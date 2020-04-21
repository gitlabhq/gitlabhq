# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddFieldsToUserPreferences < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column(:user_preferences, :timezone, :string) # rubocop:disable Migration/PreventStrings
    add_column(:user_preferences, :time_display_relative, :boolean)
    add_column(:user_preferences, :time_format_in_24h, :boolean)
  end

  def down
    remove_column(:user_preferences, :timezone)
    remove_column(:user_preferences, :time_display_relative)
    remove_column(:user_preferences, :time_format_in_24h)
  end
end
