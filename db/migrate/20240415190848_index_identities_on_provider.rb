# frozen_string_literal: true

class IndexIdentitiesOnProvider < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  disable_ddl_transaction!

  INDEX_NAME = 'index_identities_on_provider'

  def up
    add_concurrent_index :identities, :provider, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :identities, name: INDEX_NAME
  end
end
