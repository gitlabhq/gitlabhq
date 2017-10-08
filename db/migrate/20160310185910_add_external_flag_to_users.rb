# rubocop:disable all
class AddExternalFlagToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :external, :boolean, default: false
  end
end
