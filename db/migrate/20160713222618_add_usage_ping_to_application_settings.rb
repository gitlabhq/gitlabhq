class AddUsagePingToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

<<<<<<< HEAD
=======
  DOWNTIME = false

>>>>>>> ce/master
  def change
    add_column :application_settings, :usage_ping_enabled, :boolean, default: true, null: false
  end
end
