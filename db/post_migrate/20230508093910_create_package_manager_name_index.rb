# frozen_string_literal: true

class CreatePackageManagerNameIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_on_sbom_sources_package_manager_name'

  def up
    return if index_exists_by_name?(:sbom_sources, INDEX_NAME)

    disable_statement_timeout do
      execute <<~SQL
      CREATE INDEX CONCURRENTLY #{INDEX_NAME}
      ON sbom_sources
      USING BTREE ((source->'package_manager'->>'name'))
      SQL
    end
  end

  def down
    remove_concurrent_index_by_name :sbom_sources, INDEX_NAME
  end
end
