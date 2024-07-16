# frozen_string_literal: true

class RemoveSourcePackageNameFromSbomComponentsTable < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.2'

  def up
    with_lock_retries do
      remove_column :sbom_components, :source_package_name
    end
  end

  def down
    with_lock_retries do
      add_column :sbom_components, :source_package_name, :text, if_not_exists: true
    end

    add_text_limit :sbom_components, :source_package_name, 255
  end
end
