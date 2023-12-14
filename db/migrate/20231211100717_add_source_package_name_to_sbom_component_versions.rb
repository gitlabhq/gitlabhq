# frozen_string_literal: true

class AddSourcePackageNameToSbomComponentVersions < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.7'

  def up
    with_lock_retries do
      add_column :sbom_component_versions, :source_package_name, :text, if_not_exists: true
    end

    add_text_limit :sbom_component_versions, :source_package_name, 255
  end

  def down
    with_lock_retries do
      remove_column :sbom_component_versions, :source_package_name, if_exists: true
    end
  end
end
