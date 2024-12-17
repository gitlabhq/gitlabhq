# frozen_string_literal: true

class IndexStatusPagePublishedIncidentsOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_status_page_published_incidents_on_namespace_id'

  def up
    add_concurrent_index :status_page_published_incidents, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :status_page_published_incidents, INDEX_NAME
  end
end
