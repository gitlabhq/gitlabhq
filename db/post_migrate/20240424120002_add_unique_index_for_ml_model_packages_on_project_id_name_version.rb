# frozen_string_literal: true

class AddUniqueIndexForMlModelPackagesOnProjectIdNameVersion < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  disable_ddl_transaction!

  INDEX_NAME = 'uniq_idx_packages_packages_on_project_id_name_version_ml_model'

  # https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/packages/package.rb#L30
  PACKAGE_TYPE_ML_MODEL = 14
  # https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/packages/package.rb#L33
  PACKAGE_STATUS_PENDING_DESTRUCTION = 4

  # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
  def up
    add_concurrent_index(
      :packages_packages,
      %i[project_id name version],
      name: INDEX_NAME,
      unique: true,
      where: "package_type = #{PACKAGE_TYPE_ML_MODEL} AND status <> #{PACKAGE_STATUS_PENDING_DESTRUCTION}"
    )
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    remove_concurrent_index_by_name :packages_packages, INDEX_NAME
  end
end
