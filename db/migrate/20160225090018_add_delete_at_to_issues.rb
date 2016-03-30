class AddDeleteAtToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :deleted_at, :datetime
    add_index :issues, :deleted_at
  end
end
