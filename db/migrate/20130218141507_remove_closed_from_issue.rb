# rubocop:disable all
class RemoveClosedFromIssue < ActiveRecord::Migration[4.2]
  def up
    remove_column :issues, :closed
  end

  def down
    add_column :issues, :closed, :boolean
  end
end
