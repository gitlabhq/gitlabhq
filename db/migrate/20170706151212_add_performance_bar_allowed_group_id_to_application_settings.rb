class AddPerformanceBarAllowedGroupIdToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings, :performance_bar_allowed_group_id, :integer
  end
end
