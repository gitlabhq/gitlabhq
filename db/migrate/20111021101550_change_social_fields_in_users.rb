class ChangeSocialFieldsInUsers < ActiveRecord::Migration
  def up
  	change_column(:users, :skype, :string, {:null => false, :default => ''})
  	change_column(:users, :linkedin, :string, {:null => false, :default => ''})
  	change_column(:users, :twitter, :string, {:null => false, :default => ''})
  end

  def down
  end
end
