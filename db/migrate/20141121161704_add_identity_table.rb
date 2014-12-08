class AddIdentityTable < ActiveRecord::Migration
  def up
    create_table :identities do |t|
      t.string :extern_uid
      t.string :provider
      t.references :user
    end

    add_index :identities, :user_id

    User.where("provider IS NOT NULL").find_each do |user|
      execute "INSERT INTO identities(provider, extern_uid, user_id) VALUES('#{user.provider}', '#{user.extern_uid}', '#{user.id}')"
    end

    remove_column :users, :extern_uid
    remove_column :users, :provider
  end

  def down
    add_column :users, :extern_uid, :string
    add_column :users, :provider, :string

    User.where("id IN(SELECT user_id FROM identities)").find_each do |user|
      identity = user.identities.last
      user.extern_uid = identity.extern_uid
      user.provider = identity.provider
      user.save
    end

    drop_table :identities
  end
end
