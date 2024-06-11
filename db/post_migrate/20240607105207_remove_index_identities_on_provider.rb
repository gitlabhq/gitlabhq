# frozen_string_literal: true

class RemoveIndexIdentitiesOnProvider < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.1'

  INDEX_NAME = 'index_identities_on_provider'

  def up
    remove_concurrent_index_by_name :identities, name: INDEX_NAME
  end

  def down
    add_concurrent_index :identities, :provider, name: INDEX_NAME
  end
end
