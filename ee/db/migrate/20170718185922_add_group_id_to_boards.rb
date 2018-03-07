class AddGroupIdToBoards < ActiveRecord::Migration
  DOWNTIME = false

  def up
    return if group_id_exists?

    change_column_null :boards, :project_id, true

    add_column :boards, :group_id, :integer
  end

  def down
    return unless group_id_exists?

    # We cannot rollback project_id not null constraint if there are records
    # with null values.
    execute "DELETE from boards WHERE project_id IS NULL"

    remove_column :boards, :group_id
    change_column :boards, :project_id, :integer, null: false
  end

  private

  def group_id_exists?
    column_exists?(:boards, :group_id)
  end
end
