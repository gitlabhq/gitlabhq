# frozen_string_literal: true

class AddIndexPackageIdIdOnPackageFiles < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_package_files_on_package_id_id'

  def up
    disable_statement_timeout do
      execute "CREATE INDEX CONCURRENTLY #{INDEX_NAME} ON packages_package_files (package_id, id)" unless index_exists_by_name?(:package_package_files, INDEX_NAME)
    end
  end

  def down
    remove_concurrent_index_by_name :packages_package_files, INDEX_NAME
  end
end
