# rubocop:disable all
class AddLayoutOptionForUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :layout, :integer, default: 0
  end
end