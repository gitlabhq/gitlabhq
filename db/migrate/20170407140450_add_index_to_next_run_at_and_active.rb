# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexToNextRunAtAndActive < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_trigger_schedules, [:active, :next_run_at]
  end

  def down
    remove_concurrent_index :ci_trigger_schedules, [:active, :next_run_at]
  end
end
