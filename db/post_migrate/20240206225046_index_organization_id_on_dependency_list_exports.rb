# frozen_string_literal: true

class IndexOrganizationIdOnDependencyListExports < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_dependency_list_exports_on_organization_id'

  disable_ddl_transaction!
  milestone '16.10'

  def up
    add_concurrent_index :dependency_list_exports, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :dependency_list_exports, INDEX_NAME
  end
end
