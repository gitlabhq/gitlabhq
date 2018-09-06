class AddUserInternalRegexToApplicationSetting < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :application_settings, :user_default_internal_regex, :string, null: true
  end

  def down
    remove_column :application_settings, :user_default_internal_regex
  end
end
