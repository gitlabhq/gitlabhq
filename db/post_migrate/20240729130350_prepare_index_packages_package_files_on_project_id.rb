# frozen_string_literal: true

class PrepareIndexPackagesPackageFilesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_package_files_on_project_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
    prepare_async_index :packages_package_files, :project_id, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_async_index :packages_package_files, INDEX_NAME
  end
end
