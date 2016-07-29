class RemoveOldFieldsFromNamespace < ActiveRecord::Migration
  def up
    remove_column :namespaces, :ldap_cn
    remove_column :namespaces, :ldap_access
  end

  def down
    add_column :namespaces, :ldap_cn, :string, null: true
    add_column :namespaces, :ldap_access, :integer, null: true
  end
end
