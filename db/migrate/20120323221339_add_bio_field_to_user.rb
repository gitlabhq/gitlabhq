class AddBioFieldToUser < ActiveRecord::Migration
  def change
    add_column :users, :bio, :string, :null => true
  end
end
