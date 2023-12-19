# frozen_string_literal: true

class AddIndexToSamlGroupLinksOnMemberRoleId < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_saml_group_links_on_member_role_id'

  def up
    add_concurrent_index :saml_group_links, :member_role_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :saml_group_links, INDEX_NAME
  end
end
