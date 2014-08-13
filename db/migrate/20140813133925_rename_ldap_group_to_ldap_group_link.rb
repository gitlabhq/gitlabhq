class RenameLdapGroupToLdapGroupLink < ActiveRecord::Migration
  def change
    rename_table :ldap_groups, :ldap_group_links
  end
end
