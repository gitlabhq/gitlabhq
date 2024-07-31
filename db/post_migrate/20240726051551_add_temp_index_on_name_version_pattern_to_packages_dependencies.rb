# frozen_string_literal: true

class AddTempIndexOnNameVersionPatternToPackagesDependencies < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  def up
    # Temporary index to be removed in https://gitlab.com/gitlab-org/gitlab/-/issues/474578
    add_concurrent_index(
      :packages_dependencies,
      %i[name version_pattern],
      unique: true,
      name: :tmp_idx_packages_dependencies_on_name_version_pattern,
      where: 'project_id IS NULL'
    )
  end

  def down
    remove_concurrent_index_by_name(
      :packages_dependencies,
      :tmp_idx_packages_dependencies_on_name_version_pattern
    )
  end
end
