# frozen_string_literal: true

class RemoveNamespaceColumns < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  def up
    remove_column :namespaces, :unlock_membership_to_ldap
    remove_column :namespaces, :emails_disabled
  end

  def down
    add_column :namespaces, :unlock_membership_to_ldap, :boolean
    add_column :namespaces, :emails_disabled, :boolean
  end
end
