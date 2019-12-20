class AddIndexesForUserActivityQueries < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :events, [:author_id, :project_id] unless index_exists?(:events, [:author_id, :project_id])
    add_concurrent_index :user_interacted_projects, :user_id unless index_exists?(:user_interacted_projects, :user_id)
  end

  def down
    remove_concurrent_index :events, [:author_id, :project_id] if index_exists?(:events, [:author_id, :project_id])

    remove_concurrent_index :user_interacted_projects, :user_id if index_exists?(:user_interacted_projects, :user_id)
  end
end
