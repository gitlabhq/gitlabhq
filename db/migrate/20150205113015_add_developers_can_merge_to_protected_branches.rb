class AddDevelopersCanMergeToProtectedBranches < ActiveRecord::Migration
  def change
    add_column :protected_branches, :developers_can_merge, :boolean, default: false, null: false
  end
end
