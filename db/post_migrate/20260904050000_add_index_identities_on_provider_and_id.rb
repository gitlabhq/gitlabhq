# frozen_string_literal: true

class AddIndexIdentitiesOnProviderAndId < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  INDEX_NAME = 'index_identities_on_provider_and_id'

  def up
    add_concurrent_index :identities, [:provider, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :identities, INDEX_NAME
  end
end
