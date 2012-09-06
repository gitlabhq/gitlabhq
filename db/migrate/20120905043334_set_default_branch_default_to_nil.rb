class SetDefaultBranchDefaultToNil < ActiveRecord::Migration
  def up
    # Set the default_branch to allow nil, and default it to nil
    change_column_null(:projects, :default_branch, true)
    change_column_default(:projects, :default_branch, nil)
  end

  def down
    change_column_null(:projects, :default_branch, false)
    change_column_default(:projects, :default_branch, 'master')
  end
end
