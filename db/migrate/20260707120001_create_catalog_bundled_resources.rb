# frozen_string_literal: true

class CreateCatalogBundledResources < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  UNIQUE_INDEX_NAME = 'index_catalog_bundled_resources_on_fqdn_and_full_path'
  SEARCH_INDEX_NAME = 'index_catalog_bundled_resources_on_search_vector'

  def change
    create_table :catalog_bundled_resources do |t|
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :latest_released_at
      t.text :server_fqdn, null: false, limit: 255
      t.text :full_path, null: false, limit: 1024
      t.text :name, null: false, limit: 255
      t.text :description, limit: 1024
      t.virtual :search_vector, type: :tsvector, stored: true, as: <<~SQL.squish
        setweight(to_tsvector('english'::regconfig, COALESCE(name, ''::text)), 'A'::"char") ||
        setweight(to_tsvector('english'::regconfig, COALESCE(description, ''::text)), 'B'::"char")
      SQL

      t.index 'LOWER(server_fqdn), LOWER(full_path)', unique: true, name: UNIQUE_INDEX_NAME
      t.index :search_vector, using: :gin, name: SEARCH_INDEX_NAME
    end
  end
end
