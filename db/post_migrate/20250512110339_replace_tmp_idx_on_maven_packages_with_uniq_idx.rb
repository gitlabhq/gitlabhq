# frozen_string_literal: true

class ReplaceTmpIdxOnMavenPackagesWithUniqIdx < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  TABLE_NAME = :packages_packages
  INDEX_NAME = :idx_packages_on_project_id_name_version_unique_when_maven
  TMP_INDEX_NAME = :tmp_idx_packages_on_project_id_when_mvn_not_pending_destruction
  MVN_PACKAGE_TYPE = 1
  PENDING_DESTRUCTION_STATUS = 4

  def up
    add_concurrent_index(
      TABLE_NAME,
      %i[project_id name version],
      unique: true,
      name: INDEX_NAME,
      where: "package_type = #{MVN_PACKAGE_TYPE} AND status <> #{PENDING_DESTRUCTION_STATUS}"
    )
    remove_concurrent_index_by_name TABLE_NAME, TMP_INDEX_NAME
  end

  def down
    add_concurrent_index(
      TABLE_NAME,
      :project_id,
      name: TMP_INDEX_NAME,
      where: "package_type = #{MVN_PACKAGE_TYPE} AND status <> #{PENDING_DESTRUCTION_STATUS}"
    )
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
