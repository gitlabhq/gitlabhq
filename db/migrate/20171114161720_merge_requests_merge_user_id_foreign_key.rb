# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MergeRequestsMergeUserIdForeignKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  class MergeRequest < ActiveRecord::Base
    include EachBatch

    self.table_name = 'merge_requests'

    def self.with_orphaned_mergers
      where('NOT EXISTS (SELECT true FROM users WHERE merge_requests.merge_user_id = users.id)')
        .where('merge_user_id IS NOT NULL')
    end
  end

  def up
    MergeRequest.with_orphaned_mergers.each_batch(of: 100) do |batch|
      batch.update_all(merge_user_id: nil)
    end

    add_concurrent_index(
      :merge_requests,
      :merge_user_id,
      where: 'merge_user_id IS NOT NULL'
    )

    add_concurrent_foreign_key(
      :merge_requests,
      :users,
      column: :merge_user_id,
      on_delete: :nullify
    )
  end

  def down
    remove_foreign_key_without_error(:merge_requests, column: :merge_user_id)
    remove_concurrent_index(:merge_requests, :merge_user_id)
  end
end
