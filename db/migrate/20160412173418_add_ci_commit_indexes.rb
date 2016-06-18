# rubocop:disable all
class AddCiCommitIndexes < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :ci_commits, [:gl_project_id, :sha], index_options
    add_index :ci_commits, [:gl_project_id, :status], index_options
    add_index :ci_commits, [:status], index_options
  end

  private

  def index_options
    if Gitlab::Database.postgresql?
      { algorithm: :concurrently }
    else
      { }
    end
  end
end
