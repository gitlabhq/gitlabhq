# frozen_string_literal: true

class AddIndexToKeysOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  disable_ddl_transaction!

  def up
    add_concurrent_index :keys, :organization_id
  end

  def down
    remove_concurrent_index :keys, :organization_id, name: :index_keys_on_organization_id
  end
end
