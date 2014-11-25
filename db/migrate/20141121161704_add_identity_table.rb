class AddIdentityTable < ActiveRecord::Migration
  def up
    create_table :identities do |t|
      t.string :extern_uid
      t.string :provider
      t.references :user
    end

    add_index :identities, :user_id

    User.where("provider is not NULL").find_each do |user|
      execute "INSERT INTO identities(provider, extern_uid, user_id) VALUES('#{user.provider}', '#{user.extern_uid}', '#{user.id}')"
    end

    #TODO remove user's columns extern_uid and provider
  end

  def down
#TODO
  end
end
