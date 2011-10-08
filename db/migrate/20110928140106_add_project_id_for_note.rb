class AddProjectIdForNote < ActiveRecord::Migration
  def up
    add_column :notes, :project_id, :integer
  end

  def down
    remove_column :notes, :project_id, :integer
  end
end
