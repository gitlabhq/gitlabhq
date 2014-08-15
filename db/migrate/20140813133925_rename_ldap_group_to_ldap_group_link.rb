class RenameLdapGroupToLdapGroupLink < ActiveRecord::Migration
  def up
    rename_table :ldap_groups, :ldap_group_links

    # NOTE: we use the old_ methods because the new methods are overloaded
    # for backwards compatibility
    Group.where.not(ldap_cn: nil).each do |group|
      group.ldap_group_links.where(cn: group.old_ldap_cn).first_or_create do |ldap_group_link|
        ldap_group_link.group_access = group.old_ldap_access
      end
    end
  end

  def down
    rename_table :ldap_group_links, :ldap_groups
  end
end
