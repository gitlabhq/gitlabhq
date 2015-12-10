class AddIssuesStateIndex < ActiveRecord::Migration
  def change
    add_index :issues, :state
  end
end
