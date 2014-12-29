class AddDevelopersCanPushToProtectedBranches < ActiveRecord::Migration
  def change
    add_column :protected_branches, :developers_can_push, :boolean, default: false, null: false
  end
end
