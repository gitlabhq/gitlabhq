class AddEncryptedValueToVariables < ActiveRecord::Migration
  def change
    add_column :variables, :encrypted_value, :text
    add_column :variables, :encrypted_value_salt, :string
    add_column :variables, :encrypted_value_iv, :string
  end
end
