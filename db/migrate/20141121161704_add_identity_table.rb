class AddIdentityTable < ActiveRecord::Migration
  def up
    create_table :identities do |t|
      t.string :extern_uid
      t.string :provider
      t.references :user
    end

    add_index :identities, :user_id

    execute <<eos
INSERT INTO identities (provider, extern_uid, user_id)
SELECT provider, extern_uid, id FROM users
WHERE provider IS NOT NULL
eos

    if index_exists?(:users, ["extern_uid", "provider"])
      remove_index :users, ["extern_uid", "provider"]
    end

    remove_column :users, :extern_uid
    remove_column :users, :provider
  end

  def down
    add_column :users, :extern_uid, :string
    add_column :users, :provider, :string

    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      execute <<eos
UPDATE users u
SET provider = i.provider, extern_uid = i.extern_uid
FROM identities i
WHERE i.user_id = u.id
eos
      else
        execute "UPDATE users u, identities i SET u.provider = i.provider, u.extern_uid = i.extern_uid WHERE u.id = i.user_id"
      end

    drop_table :identities

    unless index_exists?(:users, ["extern_uid", "provider"])
      add_index "users", ["extern_uid", "provider"], name: "index_users_on_extern_uid_and_provider", unique: true, using: :btree
    end
  end
end
