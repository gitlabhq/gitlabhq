# frozen_string_literal: true

class AddIndexToPackagesComposerPackagesOnNameTargetShaStatusProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  TABLE_NAME = :packages_composer_packages
  INDEX_NAME = :idx_pkgs_composer_pkgs_on_name_target_sha_status_project_id

  def up
    add_concurrent_index(TABLE_NAME, %i[name target_sha status project_id], name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
