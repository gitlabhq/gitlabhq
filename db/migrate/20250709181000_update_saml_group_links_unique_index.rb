# frozen_string_literal: true

class UpdateSamlGroupLinksUniqueIndex < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_saml_group_links_on_group_id_and_saml_group_name'
  NEW_INDEX_NAME = 'index_saml_group_links_on_group_id_saml_group_name_provider'

  def up
    add_concurrent_index :saml_group_links, [:group_id, :saml_group_name, :provider], unique: true, name: NEW_INDEX_NAME
    remove_concurrent_index :saml_group_links, [:group_id, :saml_group_name], name: OLD_INDEX_NAME
  end

  def down
    remove_concurrent_index :saml_group_links, [:group_id, :saml_group_name, :provider], name: NEW_INDEX_NAME
    add_concurrent_index :saml_group_links, [:group_id, :saml_group_name], unique: true, name: OLD_INDEX_NAME
  end
end
