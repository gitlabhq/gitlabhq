# frozen_string_literal: true

class AddUnlockMembershipToLdapOfGroups < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column(:namespaces, :unlock_membership_to_ldap, :boolean)
    end
  end

  def down
    with_lock_retries do
      remove_column :namespaces, :unlock_membership_to_ldap
    end
  end
end
