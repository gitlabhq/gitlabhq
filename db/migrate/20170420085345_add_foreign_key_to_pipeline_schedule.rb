# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddForeignKeyToPipelineSchedule < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(:ci_pipeline_schedules, :ci_triggers, column: :trigger_id)
  end

  def down
    remove_foreign_key(:ci_pipeline_schedules, column: :trigger_id)
  end
end
