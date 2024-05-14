# frozen_string_literal: true

class RemoveSourcePackageNameColumnFromSbomComponents < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.0'

  INDEX = 'index_source_package_names_on_component_and_purl'

  def up
    remove_concurrent_index_by_name :sbom_components, name: INDEX
  end

  def down
    add_concurrent_index :sbom_components, [:component_type, :source_package_name, :purl_type], name: INDEX
  end
end
