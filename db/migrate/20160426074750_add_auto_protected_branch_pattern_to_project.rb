class AddAutoProtectedBranchPatternToProject < ActiveRecord::Migration
  def change
    add_column :projects, :auto_protected_branch_pattern, :string
  end
end
