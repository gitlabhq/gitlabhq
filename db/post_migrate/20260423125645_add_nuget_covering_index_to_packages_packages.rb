# frozen_string_literal: true

class AddNugetCoveringIndexToPackagesPackages < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction!

  TABLE_NAME = :packages_packages
  INDEX_NAME = 'idx_packages_on_project_id_name_status_when_nuget'
  COLUMNS = %i[project_id name status version created_at]
  WHERE_CLAUSE = 'package_type = 4 AND status <> 4'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/622
    add_concurrent_index TABLE_NAME, COLUMNS, where: WHERE_CLAUSE, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
