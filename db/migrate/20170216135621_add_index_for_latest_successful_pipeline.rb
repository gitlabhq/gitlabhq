# rubocop:disable RemoveIndex
class AddIndexForLatestSuccessfulPipeline < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:ci_commits, [:gl_project_id, :ref, :status])
  end

  def down
    remove_index :ci_commits, [:gl_project_id, :ref, :status] if index_exists? :ci_commits, [:gl_project_id, :ref, :status]
  end
end
