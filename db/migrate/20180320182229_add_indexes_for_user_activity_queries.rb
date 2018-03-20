class AddIndexesForUserActivityQueries < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :events, [:project_id, :author_id]
    add_concurrent_index :user_interacted_projects, :user_id
  end

  def down
    remove_concurrent_index :events, [:project_id, :author_id]
    remove_concurrent_index :user_interacted_projects, :user_id
  end
end
