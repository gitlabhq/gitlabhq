class AddUserInternalRegexToApplicationSetting < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :application_settings, :user_default_internal_regex, :string, null: true # rubocop:disable Migration/AddLimitToStringColumns
  end

  def down
    remove_column :application_settings, :user_default_internal_regex
  end
end
