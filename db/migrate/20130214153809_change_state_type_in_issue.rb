class ChangeStateTypeInIssue < ActiveRecord::Migration
  def up
    change_column :issues, :state, :string
  end

  def down
    change_column :issues, :state, :boolean
  end
end
