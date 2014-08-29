class RenameLdapGroupToLdapGroupLink < ActiveRecord::Migration
  def up
    rename_table :ldap_groups, :ldap_group_links

    # NOTE: we use the old_ methods because the new methods are overloaded
    # for backwards compatibility

    Group.where.not(ldap_cn: nil).each do |group|
      # Make sure we use the database column, not the model methods
      ldap_cn = group.read_attribute(:ldap_cn)
      ldap_access = group.read_attribute(:ldap_access)

      group.ldap_group_links.where(cn: ldap_cn).first_or_create do |ldap_group_link|
        ldap_group_link.group_access = ldap_access
      end
    end
  end

  def down
    rename_table :ldap_group_links, :ldap_groups
  end
end
