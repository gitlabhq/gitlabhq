class AddUsagePingToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def change
    add_column :application_settings, :usage_ping_enabled, :boolean, default: true, null: false
  end
end
