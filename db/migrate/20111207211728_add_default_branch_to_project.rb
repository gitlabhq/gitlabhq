class AddDefaultBranchToProject < ActiveRecord::Migration
  def change
    add_column :projects, :default_branch, :string, :null => false, :default => "master"
  end
end
