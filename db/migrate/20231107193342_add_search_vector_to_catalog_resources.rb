# frozen_string_literal: true

class AddSearchVectorToCatalogResources < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  def up
    # This is required to implement PostgreSQL Full Text Search functionality in Ci::Catalog::Resource.
    # Indices on `search_vector` will be added in a later step. COALESCE is used here to avoid NULL results.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/430889 for details.
    execute <<~SQL
      ALTER TABLE catalog_resources
        ADD COLUMN search_vector tsvector
          GENERATED ALWAYS AS
            (setweight(to_tsvector('english', COALESCE(name, '')), 'A') ||
             setweight(to_tsvector('english', COALESCE(description, '')), 'B')) STORED;
    SQL
  end

  def down
    remove_column :catalog_resources, :search_vector
  end
end
