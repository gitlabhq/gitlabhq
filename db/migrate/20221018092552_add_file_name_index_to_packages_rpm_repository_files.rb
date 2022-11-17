# frozen_string_literal: true

class AddFileNameIndexToPackagesRpmRepositoryFiles < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  NEW_INDEX_NAME = 'index_packages_rpm_repository_files_on_project_id_and_file_name'
  OLD_INDEX_NAME = 'index_packages_rpm_repository_files_on_project_id'

  def up
    add_concurrent_index :packages_rpm_repository_files, %i[project_id file_name], name: NEW_INDEX_NAME
    remove_concurrent_index :packages_rpm_repository_files, :project_id, name: OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :packages_rpm_repository_files, :project_id, name: OLD_INDEX_NAME
    remove_concurrent_index :packages_rpm_repository_files, %i[project_id file_name], name: NEW_INDEX_NAME
  end
end
