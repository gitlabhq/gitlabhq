# frozen_string_literal: true

class AddSourcePackageNameToSbomComponent < Gitlab::Database::Migration[2.2]
  milestone '16.6'
  disable_ddl_transaction!

  INDEX = 'index_source_package_names_on_component_and_purl'

  def up
    with_lock_retries do
      add_column :sbom_components, :source_package_name, :text, if_not_exists: true
    end

    add_text_limit :sbom_components, :source_package_name, 255
    add_concurrent_index :sbom_components,
      [:component_type, :source_package_name, :purl_type],
      name: INDEX,
      unique: true
  end

  def down
    with_lock_retries do
      remove_column :sbom_components, :source_package_name, if_exists: true
    end

    remove_concurrent_index_by_name :sbom_components, name: INDEX
  end
end
