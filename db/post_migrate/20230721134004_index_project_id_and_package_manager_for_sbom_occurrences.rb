# frozen_string_literal: true

class IndexProjectIdAndPackageManagerForSbomOccurrences < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_sbom_occurrences_on_project_id_and_package_manager'

  disable_ddl_transaction!

  def up
    add_concurrent_index :sbom_occurrences, [:project_id, :package_manager], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_occurrences, INDEX_NAME
  end
end
