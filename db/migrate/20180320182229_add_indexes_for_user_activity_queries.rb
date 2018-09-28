class AddIndexesForUserActivityQueries < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :events, [:author_id, :project_id] unless index_exists?(:events, [:author_id, :project_id])
    add_concurrent_index :user_interacted_projects, :user_id unless index_exists?(:user_interacted_projects, :user_id)
  end

  def down
    remove_concurrent_index :events, [:author_id, :project_id] if index_exists?(:events, [:author_id, :project_id])

    patch_foreign_keys do
      remove_concurrent_index :user_interacted_projects, :user_id if index_exists?(:user_interacted_projects, :user_id)
    end
  end

  private

  def patch_foreign_keys
    return yield if Gitlab::Database.postgresql?

    # MySQL doesn't like to remove the index with a foreign key using it.
    remove_foreign_key :user_interacted_projects, :users if fk_exists?(:user_interacted_projects, :user_id)

    yield

    # Let's re-add the foreign key using the existing index on (user_id, project_id)
    add_concurrent_foreign_key :user_interacted_projects, :users, column: :user_id unless fk_exists?(:user_interacted_projects, :user_id)
  end

  def fk_exists?(table, column)
    foreign_keys(table).any? do |key|
      key.options[:column] == column.to_s
    end
  end
end
