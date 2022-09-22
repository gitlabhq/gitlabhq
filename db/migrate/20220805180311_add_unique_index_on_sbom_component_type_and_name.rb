# frozen_string_literal: true

class AddUniqueIndexOnSbomComponentTypeAndName < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_sbom_components_on_component_type_and_name'

  disable_ddl_transaction!

  def up
    add_concurrent_index :sbom_components, [:component_type, :name], unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_components, name: INDEX_NAME
  end
end
