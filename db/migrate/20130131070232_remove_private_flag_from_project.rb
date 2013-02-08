class RemovePrivateFlagFromProject < ActiveRecord::Migration
  def up
    remove_column :projects, :private_flag
  end

  def down
    add_column :projects, :private_flag, :boolean, default: true, null: false
  end
end
