class AddGroupIdToMilestones < ActiveRecord::Migration
  DOWNTIME = false

  def up
    return if column_exists? :milestones, :group_id

    change_column_null :milestones, :project_id, true

    add_column :milestones, :group_id, :integer
  end

  def down
    # We cannot rollback project_id not null constraint if there are records
    # with null values.
    execute "DELETE from milestones WHERE project_id IS NULL"

    remove_foreign_key_for_mysql(:groups)
    remove_column :milestones, :group_id

    remove_foreign_key_for_mysql(:projects)
    change_column :milestones, :project_id, :integer, null: false
    add_foreign_key_for_mysql(:projects)
  end

  private

  # Create the foreign key explicitly for MySQL.
  def add_foreign_key_for_mysql(target)
    if Gitlab::Database.mysql? && !foreign_key_exists?(:milestones, target)
      add_foreign_key :milestones, target, on_delete: :cascade
    end
  end

  # Drop the foreign key explicitly for MySQL.
  def remove_foreign_key_for_mysql(target)
    if Gitlab::Database.mysql? && foreign_key_exists?(:milestones, target)
      remove_foreign_key :milestones, target
    end
  end
end
