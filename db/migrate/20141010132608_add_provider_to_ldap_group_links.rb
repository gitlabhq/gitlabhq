class AddProviderToLdapGroupLinks < ActiveRecord::Migration
  def change
    add_column :ldap_group_links, :provider, :string
  end
end
