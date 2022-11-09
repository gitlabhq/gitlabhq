# frozen_string_literal: true

class AddUniqueIndexOnSbomComponentsTypeNameAndPurlType < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_sbom_components_on_component_type_name_and_purl_type'

  disable_ddl_transaction!

  def up
    add_concurrent_index :sbom_components, [:name, :purl_type, :component_type], unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_components, name: INDEX_NAME
  end
end
