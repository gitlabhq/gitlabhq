# frozen_string_literal: true

class PrepareIndexForOrgIdOnNamespaces < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_namespaces_on_organization_id'

  def up
    prepare_async_index :namespaces, :organization_id, name: INDEX_NAME
  end

  def down
    unprepare_async_index :namespaces, :organization_id, name: INDEX_NAME
  end
end
