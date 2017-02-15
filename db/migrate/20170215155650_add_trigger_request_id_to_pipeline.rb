# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddTriggerRequestIdToPipeline < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_commits, :trigger_id, :integer
    add_column :ci_commits, :trigger_variables, :text
    add_foreign_key :ci_commits, :ci_triggers, column: "trigger_id", on_delete: :cascade
  end
end
