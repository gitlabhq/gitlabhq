class RenameLdapGroupToLdapGroupLink < ActiveRecord::Migration
  def up
    rename_table :ldap_groups, :ldap_group_links

    # NOTE: we use the old_ methods because the new methods are overloaded
    # for backwards compatibility
    time = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    execute "INSERT INTO ldap_group_links ( group_access, cn, group_id, created_at, updated_at )
             SELECT ldap_access, ldap_cn, id, DATE('#{time}'), DATE('#{time}') FROM namespaces
             WHERE ldap_cn IS NOT NULL;"
  end

  def down
    rename_table :ldap_group_links, :ldap_groups
  end
end
