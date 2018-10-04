class AddMirrorAvailableToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :mirror_available, :boolean, default: true, allow_null: false) unless column_exists?(:application_settings, :mirror_available)
  end

  def down
    remove_column(:application_settings, :mirror_available) if column_exists?(:application_settings, :mirror_available)
  end
end
