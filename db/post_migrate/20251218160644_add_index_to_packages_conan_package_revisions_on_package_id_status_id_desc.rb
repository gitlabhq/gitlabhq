# frozen_string_literal: true

class AddIndexToPackagesConanPackageRevisionsOnPackageIdStatusIdDesc < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.8'

  TABLE = :packages_conan_package_revisions
  INDEX = :idx_pkgs_conan_package_revisions_on_package_id_status_id_desc

  def up
    add_concurrent_index TABLE, %i[package_id status id], order: { id: :desc }, name: INDEX
  end

  def down
    remove_concurrent_index_by_name TABLE, INDEX
  end
end
