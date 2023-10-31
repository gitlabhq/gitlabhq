# frozen_string_literal: true

class RemoveTempIndexToPackagesOnProjectIdWhenNpmAndNotPendingDestruction < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.7'

  INDEX_NAME = 'tmp_idx_packages_on_project_id_when_npm_not_pending_destruction'
  NPM_PACKAGE_TYPE = 2
  PENDING_DESTRUCTION_STATUS = 4

  def up
    remove_concurrent_index_by_name :packages_packages, INDEX_NAME
  end

  def down
    add_concurrent_index(
      :packages_packages,
      :project_id,
      name: INDEX_NAME,
      where: "package_type = #{NPM_PACKAGE_TYPE} AND status <> #{PENDING_DESTRUCTION_STATUS}"
    )
  end
end
