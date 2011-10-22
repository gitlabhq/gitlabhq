class ChangeSocialFieldsInUsers < ActiveRecord::Migration
  def up
    remove_column :users, :skype
    remove_column :users, :linkedin
    remove_column :users, :twitter

    add_column :users, :skype, :string, {:null => false, :default => ''}
    add_column :users, :linkedin, :string, {:null => false, :default => ''}
    add_column :users, :twitter, :string, {:null => false, :default => ''}
  end

  def down
  end
end
