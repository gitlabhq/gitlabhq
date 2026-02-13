# frozen_string_literal: true

class PrepareAsyncIndexToPackagesPackageFilesOnPackageIdFileNameFileSha1 < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  TABLE_NAME = :packages_package_files
  INDEX_NAME = :index_packages_package_files_on_package_id_file_name_file_sha1
  COLUMNS = %i[package_id file_name file_sha1]

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/554107
  def up
    # rubocop:disable Migration/PreventIndexCreation -- The index will replace existing index index_packages_package_files_on_package_id_and_file_name
    prepare_async_index TABLE_NAME, COLUMNS, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_async_index TABLE_NAME, COLUMNS, name: INDEX_NAME
  end
end
