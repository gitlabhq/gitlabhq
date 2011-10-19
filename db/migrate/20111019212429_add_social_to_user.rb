class AddSocialToUser < ActiveRecord::Migration
  def change
    add_column :users, :skype, :string
    add_column :users, :linkedin, :string
    add_column :users, :twitter, :string
  end
end
