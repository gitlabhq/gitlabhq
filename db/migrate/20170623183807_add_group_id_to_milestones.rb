class AddGroupIdToMilestones < ActiveRecord::Migration
  DOWNTIME = false

  def up
    change_column_null :milestones, :project_id, true

    add_column :milestones, :group_id, :integer
  end

  def down
    remove_column :milestones, :group_id
    change_column_null :milestones, :project_id, true

    # We cannot rollback project_id not null constraint if there are records
    # with null values.
    execute "DELETE from milestones WHERE project_id IS NULL"
  end
end
