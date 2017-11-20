# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MergeRequestsMilestoneIdForeignKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  class MergeRequest < ActiveRecord::Base
    include EachBatch

    self.table_name = 'merge_requests'

    def self.with_orphaned_milestones
      where('NOT EXISTS (SELECT true FROM milestones WHERE merge_requests.milestone_id = milestones.id)')
        .where('milestone_id IS NOT NULL')
    end
  end

  def up
    MergeRequest.with_orphaned_milestones.each_batch(of: 100) do |batch|
      batch.update_all(milestone_id: nil)
    end

    add_concurrent_foreign_key(
      :merge_requests,
      :milestones,
      column: :milestone_id,
      on_delete: :nullify
    )
  end

  def down
    remove_foreign_key_without_error(:merge_requests, column: :milestone_id)
  end
end
