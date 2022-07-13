# frozen_string_literal: true

class AddIndexOnInstallablePackageFiles < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_pkgs_installable_package_files_on_package_id_id_file_name'
  # See https://gitlab.com/gitlab-org/gitlab/-/blob/e3ed2c1f65df2e137fc714485d7d42264a137968/app/models/packages/package_file.rb#L16
  DEFAULT_STATUS = 0

  def up
    add_concurrent_index :packages_package_files,
                         [:package_id, :id, :file_name],
                         where: "(status = #{DEFAULT_STATUS})",
                         name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_package_files, INDEX_NAME
  end
end
