# rubocop:disable all
class AddIssuesStateIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :issues, :state
  end
end
