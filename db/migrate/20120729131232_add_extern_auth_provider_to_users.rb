class AddExternAuthProviderToUsers < ActiveRecord::Migration
  def change
    add_column :users, :extern_uid, :string
    add_column :users, :provider, :string

    add_index :users, [:extern_uid, :provider], :unique => true
  end
end
