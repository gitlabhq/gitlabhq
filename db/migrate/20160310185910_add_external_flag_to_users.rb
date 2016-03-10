class AddExternalFlagToUsers < ActiveRecord::Migration
  def change
    add_column :users, :external, :boolean, default: false
  end
end
