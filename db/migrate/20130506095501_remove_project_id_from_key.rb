class RemoveProjectIdFromKey < ActiveRecord::Migration
  def up
    remove_column :keys, :project_id
  end

  def down
    add_column :keys, :project_id, :integer
  end
end
