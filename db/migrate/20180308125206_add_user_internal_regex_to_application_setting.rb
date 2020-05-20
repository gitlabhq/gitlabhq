class AddUserInternalRegexToApplicationSetting < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def up
    add_column :application_settings, :user_default_internal_regex, :string, null: true
  end
  # rubocop:enable Migration/PreventStrings

  def down
    remove_column :application_settings, :user_default_internal_regex
  end
end
