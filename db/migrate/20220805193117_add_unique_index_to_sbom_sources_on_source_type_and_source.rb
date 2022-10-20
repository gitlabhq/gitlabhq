# frozen_string_literal: true

class AddUniqueIndexToSbomSourcesOnSourceTypeAndSource < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_sbom_sources_on_source_type_and_source'

  disable_ddl_transaction!

  def up
    add_concurrent_index :sbom_sources, [:source_type, :source], unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_sources, name: INDEX_NAME
  end
end
