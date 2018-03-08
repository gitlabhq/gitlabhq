class AddGroupIdToBoardsCe < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    return if group_id_exists?

    add_column :boards, :group_id, :integer
    add_foreign_key :boards, :namespaces, column: :group_id, on_delete: :cascade
    add_concurrent_index :boards, :group_id

    change_column_null :boards, :project_id, true
  end

  def down
    return unless group_id_exists?

    remove_foreign_key :boards, column: :group_id
    remove_index :boards, :group_id if index_exists? :boards, :group_id
    remove_column :boards, :group_id

    execute "DELETE from boards WHERE project_id IS NULL"
    change_column_null :boards, :project_id, false
  end

  private

  def group_id_exists?
    column_exists?(:boards, :group_id)
  end
end
