class AddLdapAccessToGroup < ActiveRecord::Migration
  def change
    add_column :namespaces, :ldap_access, :integer, null: true
  end
end
