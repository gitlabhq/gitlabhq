class AddIndexesForUserActivityQueries < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :events, [:author_id, :project_id]
    add_concurrent_index :user_interacted_projects, :user_id
  end

  def down
    remove_concurrent_index :events, [:author_id, :project_id]

    patch_foreign_keys do
      remove_concurrent_index :user_interacted_projects, :user_id
    end
  end

  private

  def patch_foreign_keys
    # MySQL doesn't like to remove the index with a foreign key using it.
    remove_foreign_key :user_interacted_projects, :users unless Gitlab::Database.postgresql?
    yield
    # Let's re-add the foreign key using the existing index on (user_id, project_id)
    add_concurrent_foreign_key :user_interacted_projects, :users, column: :user_id unless Gitlab::Database.postgresql?
  end
end
