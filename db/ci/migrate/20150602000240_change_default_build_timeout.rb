class ChangeDefaultBuildTimeout < ActiveRecord::Migration
  def up
    change_column :projects, :timeout, :integer, default: 3600, null: false
  end

  def down
    change_column :projects, :timeout, :integer, default: 1800, null: false
  end
end
