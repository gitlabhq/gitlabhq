class AddProtectedBranchPatternToProject < ActiveRecord::Migration
  def change
    add_column :projects, :protected_branch_pattern, :string
  end
end
