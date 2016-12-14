class AddLimitBuildMinutesToRunners < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :runners, :limit_build_minutes, :boolean
  end
end
