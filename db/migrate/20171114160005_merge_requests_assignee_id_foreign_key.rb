# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MergeRequestsAssigneeIdForeignKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  class MergeRequest < ActiveRecord::Base
    include EachBatch

    self.table_name = 'merge_requests'

    def self.with_orphaned_assignees
      where('NOT EXISTS (SELECT true FROM users WHERE merge_requests.assignee_id = users.id)')
        .where('assignee_id IS NOT NULL')
    end
  end

  def up
    MergeRequest.with_orphaned_assignees.each_batch(of: 100) do |batch|
      batch.update_all(assignee_id: nil)
    end

    add_concurrent_foreign_key(
      :merge_requests,
      :users,
      column: :assignee_id,
      on_delete: :nullify
    )
  end

  def down
    remove_foreign_key(:merge_requests, column: :assignee_id)
  end
end
