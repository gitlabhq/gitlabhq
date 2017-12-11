# rubocop:disable Migration/RemoveColumn
# rubocop:disable RemoveIndex
class RemoveOldProjectIdColumns < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = true
  DOWNTIME_REASON = 'Unused columns are being removed.'

  def up
    remove_index :ci_builds, :project_id if
      index_exists?(:ci_builds, :project_id)

    remove_column :ci_builds, :project_id
    remove_column :ci_commits, :project_id
    remove_column :ci_runner_projects, :project_id
    remove_column :ci_triggers, :project_id
    remove_column :ci_variables, :project_id
  end

  def down
    add_column :ci_builds, :project_id, :integer
    add_column :ci_commits, :project_id, :integer
    add_column :ci_runner_projects, :project_id, :integer
    add_column :ci_triggers, :project_id, :integer
    add_column :ci_variables, :project_id, :integer

    add_concurrent_index :ci_builds, :project_id
  end
end
