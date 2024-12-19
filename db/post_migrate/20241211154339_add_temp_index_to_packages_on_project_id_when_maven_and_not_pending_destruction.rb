# frozen_string_literal: true

class AddTempIndexToPackagesOnProjectIdWhenMavenAndNotPendingDestruction < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.8'

  INDEX_NAME = 'tmp_idx_packages_on_project_id_when_mvn_not_pending_destruction'
  MVN_PACKAGE_TYPE = 1
  PENDING_DESTRUCTION_STATUS = 4

  def up
    # Temporary index to be removed in 17.9
    add_concurrent_index( # rubocop:disable Migration/PreventIndexCreation -- temp index to be used in a background migration then removed
      :packages_packages,
      :project_id,
      name: INDEX_NAME,
      where: "package_type = #{MVN_PACKAGE_TYPE} AND status <> #{PENDING_DESTRUCTION_STATUS}"
    )
  end

  def down
    remove_concurrent_index_by_name :packages_packages, INDEX_NAME
  end
end
