class AddAccessLevelToCiRunners < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # Ci::Runner.unprotected: 0
    add_column_with_default(:ci_runners, :access_level, :integer, default: 0)
  end

  def down
    remove_column(:ci_runners, :access_level)
  end
end
