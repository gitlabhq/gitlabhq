# rubocop:disable all
class AddDeleteAtToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :deleted_at, :datetime
    add_index :issues, :deleted_at
  end
end
