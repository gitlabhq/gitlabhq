# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexForRecentPushEvents < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index_if_not_present(
      :merge_requests,
      [:source_project_id, :source_branch]
    )

    remove_concurrent_index_if_present(:merge_requests, :source_project_id)
  end

  def down
    add_concurrent_index_if_not_present(:merge_requests, :source_project_id)

    remove_concurrent_index_if_present(
      :merge_requests,
      [:source_project_id, :source_branch]
    )
  end

  def add_concurrent_index_if_not_present(table, columns)
    return if index_exists?(table, columns)

    add_concurrent_index(table, columns)
  end

  def remove_concurrent_index_if_present(table, columns)
    return unless index_exists?(table, columns)

    remove_concurrent_index(table, columns)
  end
end
