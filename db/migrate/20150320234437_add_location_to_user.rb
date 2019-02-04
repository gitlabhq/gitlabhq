class AddLocationToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :location, :string
  end
end
