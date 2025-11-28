# frozen_string_literal: true

class RemoveTempSourceIdFromGroupScimIdentities < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  INDEX_NAME = 'index_group_scim_identities_on_temp_source_id'

  def up
    remove_column :group_scim_identities, :temp_source_id
  end

  def down
    add_column :group_scim_identities, :temp_source_id, :bigint
    change_column_comment :group_scim_identities, :temp_source_id, 'Temporary column to store scim_idenity id'
    add_concurrent_index :group_scim_identities, :temp_source_id, unique: true, name: INDEX_NAME
  end
end
