class AddLastActivityColumnIntoProject < ActiveRecord::Migration
  def up
    add_column :projects, :last_activity_at, :datetime
    add_index :projects, :last_activity_at

    Project.find_each do |project|
      last_activity_date = if project.last_activity
                             project.last_activity.created_at
                           else
                             project.updated_at
                           end

      project.update_attribute(:last_activity_at, last_activity_date)
    end
  end

  def down
    remove_index :projects, :last_activity_at
    remove_column :projects, :last_activity_at
  end
end
