# frozen_string_literal: true

class AddSearchVectorIndexToCatalogResources < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.8'

  INDEX_NAME = 'index_catalog_resources_on_search_vector_triagram'

  def up
    disable_statement_timeout do
      execute <<-SQL
        CREATE INDEX CONCURRENTLY IF NOT EXISTS #{INDEX_NAME} ON catalog_resources
          USING GIN (search_vector);
      SQL
    end
  end

  def down
    remove_concurrent_index_by_name :catalog_resources, name: INDEX_NAME
  end
end
