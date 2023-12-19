# frozen_string_literal: true

class DropIndexFromSbomComponents < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.7'

  INDEX = 'index_source_package_names_on_component_and_purl'

  def up
    remove_concurrent_index_by_name :sbom_components, name: INDEX
    add_concurrent_index :sbom_components,
      [:component_type, :source_package_name, :purl_type],
      name: INDEX
  end

  def down
    # no-op
  end
end
