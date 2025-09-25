# frozen_string_literal: true

class IndexWebHooksOnOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  INDEX_NAME = 'index_web_hooks_on_organization_id'

  def up
    add_concurrent_index :web_hooks, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :web_hooks, INDEX_NAME, if_exists: true
  end
end
