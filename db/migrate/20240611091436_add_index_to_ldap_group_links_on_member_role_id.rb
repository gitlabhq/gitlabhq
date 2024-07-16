# frozen_string_literal: true

class AddIndexToLdapGroupLinksOnMemberRoleId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_ldap_group_links_on_member_role_id'

  def up
    add_concurrent_index :ldap_group_links, :member_role_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ldap_group_links, INDEX_NAME
  end
end
