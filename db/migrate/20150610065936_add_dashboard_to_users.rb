# rubocop:disable all
class AddDashboardToUsers < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :dashboard, :integer, default: 0
  end

  def down
    remove_column :users, :dashboard
  end
end
