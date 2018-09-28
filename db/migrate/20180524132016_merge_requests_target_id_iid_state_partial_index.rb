# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MergeRequestsTargetIdIidStatePartialIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  INDEX_NAME = 'index_merge_requests_on_target_project_id_and_iid_opened'

  disable_ddl_transaction!

  def up
    # On GitLab.com this index will take up roughly 5 MB of space.
    add_concurrent_index(
      :merge_requests,
      [:target_project_id, :iid],
      where: "state = 'opened'",
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(:merge_requests, INDEX_NAME)
  end
end
