# frozen_string_literal: true

class AddConcurrentIndexToPoolRepositoriesOnOrganizationId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.8'

  INDEX_NAME = 'index_pool_repositories_on_organization_id'

  def up
    add_concurrent_index :pool_repositories, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :pool_repositories, INDEX_NAME
  end
end
