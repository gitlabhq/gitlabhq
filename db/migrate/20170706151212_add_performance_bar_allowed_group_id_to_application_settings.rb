class AddPerformanceBarAllowedGroupIdToApplicationSettings < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings, :performance_bar_allowed_group_id, :integer
  end
end
