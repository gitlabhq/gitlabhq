class AddLdapSettingsToGroup < ActiveRecord::Migration
  def change
    add_column :namespaces, :ldap_cn, :string, null: true
  end
end
