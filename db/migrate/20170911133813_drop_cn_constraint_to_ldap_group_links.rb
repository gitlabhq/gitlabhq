class DropCnConstraintToLdapGroupLinks < ActiveRecord::Migration
  DOWNTIME = false

  def change
    change_column_null :ldap_group_links, :cn, true
  end
end
