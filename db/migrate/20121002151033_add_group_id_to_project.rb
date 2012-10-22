class AddGroupIdToProject < ActiveRecord::Migration
  def change
    add_column :projects, :group_id, :integer
  end
end
