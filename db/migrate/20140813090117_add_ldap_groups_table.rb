class AddLdapGroupsTable < ActiveRecord::Migration
  def up
    create_table :ldap_groups do |t|
      t.string :cn, null: false
      t.integer :group_access, null: false
      t.references :group, null: false

      t.timestamps
    end

    Group.where.not(ldap_cn: nil).each do |group|
      group.ldap_groups.where(cn: group.ldap_cn).first_or_create do |ldap_group|
        ldap_group.group_access = group.ldap_access
      end
    end
  end

  def down
    drop_table :ldap_groups
  end
end
