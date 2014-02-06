class RemoveDefaultBranch < ActiveRecord::Migration
  def up
    remove_column :projects, :default_branch
  end

  def down
    add_column :projects, :default_branch, :string
  end
end
