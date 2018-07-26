# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UpdateProjectIndexes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  NEW_INDEX_NAME = 'idx_project_repository_check_partial'

  disable_ddl_transaction!

  def up
    add_concurrent_index(:projects,
      [:repository_storage, :created_at],
      name: NEW_INDEX_NAME,
      where: 'last_repository_check_at IS NULL'
                        )
  end

  def down
    remove_concurrent_index_by_name(:projects, NEW_INDEX_NAME)
  end
end
