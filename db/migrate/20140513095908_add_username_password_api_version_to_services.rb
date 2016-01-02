class AddUsernamePasswordApiVersionToServices < ActiveRecord::Migration
  def change
    add_column :services, :username, :string
    add_column :services, :password, :string
    add_column :services, :api_version, :string
  end
end
