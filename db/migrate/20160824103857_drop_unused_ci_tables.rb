class DropUnusedCiTables < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    drop_table(:ci_services)
    drop_table(:ci_web_hooks)
  end
end
