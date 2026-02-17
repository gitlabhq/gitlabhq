# frozen_string_literal: true

class AsyncDropIndexNamespacesOnOrganizationIdForGroups < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  INDEX_NAME = 'index_namespaces_on_organization_id_for_groups'

  def up
    prepare_async_index_removal :namespaces, :organization_id, name: INDEX_NAME
  end

  def down
    unprepare_async_index :namespaces, :organization_id, name: INDEX_NAME
  end
end
