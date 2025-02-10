# frozen_string_literal: true

class AddScimGroupUidToSamlGroupLinks < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  INDEX_NAME = 'index_saml_group_links_on_scim_group_uid'

  def up
    with_lock_retries do
      add_column :saml_group_links, :scim_group_uid, :uuid
    end

    add_concurrent_index :saml_group_links, :scim_group_uid, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :saml_group_links, :scim_group_uid, name: INDEX_NAME

    with_lock_retries do
      remove_column :saml_group_links, :scim_group_uid
    end
  end
end
