# rubocop:disable all
class AddApiKeyToServices < ActiveRecord::Migration[4.2]
  def change
    add_column :services, :api_key, :string
  end
end
