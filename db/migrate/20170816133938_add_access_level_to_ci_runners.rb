class AddAccessLevelToCiRunners < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:ci_runners, :access_level, :integer,
                            default: Ci::Runner.access_levels['not_protected'])
  end

  def down
    remove_column(:ci_runners, :access_level)
  end
end
