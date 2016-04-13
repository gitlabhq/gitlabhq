class AddCiCommitIndexes < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :ci_commits, [:gl_project_id, :sha], index_options
    add_index :ci_commits, [:gl_project_id, :status], index_options
    add_index :ci_commits, [:status], index_options
  end

  def index_options
    { algorithm: :concurrently } if Gitlab::Database.postgresql?
  end
end
