class AddFilterToLdapGroupLinks < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column(:ldap_group_links, :filter, :string)
  end
end
