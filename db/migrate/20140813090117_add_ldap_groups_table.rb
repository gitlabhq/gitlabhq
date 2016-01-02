class AddLdapGroupsTable < ActiveRecord::Migration
  def up
    create_table :ldap_groups do |t|
      t.string :cn, null: false
      t.integer :group_access, null: false
      t.references :group, null: false

      t.timestamps
    end
  end

  def down
    drop_table :ldap_groups
  end
end
