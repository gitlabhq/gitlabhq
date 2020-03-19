# frozen_string_literal: true

class AddIndexOnIdAndLdapKeyToKeys < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_keys_on_id_and_ldap_key_type'

  disable_ddl_transaction!

  def up
    add_concurrent_index :keys, [:id], where: "type = 'LDAPKey'", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :keys, INDEX_NAME
  end
end
