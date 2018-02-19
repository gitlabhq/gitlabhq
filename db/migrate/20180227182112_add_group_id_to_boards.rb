# This is part of a backport from EE group boards feature which a few extra steps
# are required on this migration since it will be merged into EE which already
# contains the group_id column.
# like checking if the group_id column already exists before adding it.

class AddGroupIdToBoards < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    unless group_id_exists?
      add_column :boards, :group_id, :integer
      add_foreign_key :boards, :namespaces, column: :group_id, on_delete: :cascade
      add_concurrent_index :boards, :group_id

      change_column_null :boards, :project_id, true
    end
  end

  def down
    if group_id_exists?
      remove_foreign_key :boards, column: :group_id
      remove_index :boards, :group_id if index_exists? :boards, :group_id
      remove_column :boards, :group_id

      execute "DELETE from boards WHERE project_id IS NULL"
      change_column_null :boards, :project_id, false
    end
  end

  private

  def group_id_exists?
    column_exists?(:boards, :group_id)
  end
end
