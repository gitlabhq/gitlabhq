# rubocop:disable all
class AddStateToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :state, :string
  end
end
