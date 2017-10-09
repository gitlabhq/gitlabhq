class AddUserDefaultExternalToApplicationSettings < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :user_default_external, :boolean,
                            default: false, allow_null: false)
  end

  def down
    remove_column(:application_settings, :user_default_external)
  end
end
