# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddForeignKeyForMergeRequestDiffs < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    execute <<-EOF
    DELETE FROM merge_request_diffs
    WHERE NOT EXISTS (
      SELECT true
      FROM merge_requests
      WHERE merge_requests.id = merge_request_diffs.merge_request_id
    )
    EOF

    add_concurrent_foreign_key(:merge_request_diffs,
                               :merge_requests,
                               column: :merge_request_id)
  end

  def down
    remove_foreign_key(:merge_request_diffs, column: :merge_request_id)
  end
end
