# frozen_string_literal: true

class AddTmpUniquePackagesIndexWhenDebian < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :packages_packages
  PACKAGE_TYPE_DEBIAN = 9
  PACKAGE_STATUS_PENDING_DESTRUCTION = 4
  TMP_DEBIAN_UNIQUE_INDEX_NAME = 'tmp_unique_packages_project_id_and_name_and_version_when_debian'

  disable_ddl_transaction!

  def up
    # This index will disallow further duplicates while we're deduplicating the data.
    add_concurrent_index TABLE_NAME, [:project_id, :name, :version],
      where: "package_type = #{PACKAGE_TYPE_DEBIAN} AND status != #{PACKAGE_STATUS_PENDING_DESTRUCTION} AND
        created_at > TIMESTAMP WITH TIME ZONE '#{Time.now.utc}'",
      unique: true,
      name: TMP_DEBIAN_UNIQUE_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, TMP_DEBIAN_UNIQUE_INDEX_NAME
  end
end
