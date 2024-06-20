# frozen_string_literal: true

class AddMemberRoleIdToLdapGroupLinks < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  enable_lock_retries!

  def change
    add_column :ldap_group_links, :member_role_id, :bigint
  end
end
