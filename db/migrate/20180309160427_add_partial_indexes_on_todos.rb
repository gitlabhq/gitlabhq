# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddPartialIndexesOnTodos < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

   disable_ddl_transaction!

   INDEX_NAME_PENDING="index_todos_on_user_id_and_id_pending"
   INDEX_NAME_DONE="index_todos_on_user_id_and_id_done"
   
  def up
    unless index_exists?(:todos, [:user_id, :id], name: INDEX_NAME_PENDING)
      add_concurrent_index(:todos, [:user_id, :id], where: "state='pending'", name: INDEX_NAME_PENDING)
    end
    unless index_exists?(:todos, [:user_id, :id], name: INDEX_NAME_DONE)
      add_concurrent_index(:todos, [:user_id, :id], where: "state='done'", name: INDEX_NAME_DONE)
    end
  end

  def down
    remove_concurrent_index(:todos, [:user_id, :id], where: "state='pending'", name: INDEX_NAME_PENDING)
    remove_concurrent_index(:todos, [:user_id, :id], where: "state='done'", name: INDEX_NAME_DONE)
  end    
end
