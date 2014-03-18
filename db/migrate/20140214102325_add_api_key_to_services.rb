class AddApiKeyToServices < ActiveRecord::Migration
  def change
    add_column :services, :api_key, :string
  end
end
