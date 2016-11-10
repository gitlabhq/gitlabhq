class DropUnusedCiTables < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    drop_table(:ci_services)
    drop_table(:ci_web_hooks)
  end
end
