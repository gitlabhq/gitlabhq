# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MergeRequestsUpdatedByIdForeignKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  class MergeRequest < ActiveRecord::Base
    include EachBatch

    self.table_name = 'merge_requests'

    def self.with_orphaned_updaters
      where('NOT EXISTS (SELECT true FROM users WHERE merge_requests.updated_by_id = users.id)')
        .where('updated_by_id IS NOT NULL')
    end
  end

  def up
    MergeRequest.with_orphaned_updaters.each_batch(of: 100) do |batch|
      batch.update_all(updated_by_id: nil)
    end

    add_concurrent_index(
      :merge_requests,
      :updated_by_id,
      where: 'updated_by_id IS NOT NULL'
    )

    add_concurrent_foreign_key(
      :merge_requests,
      :users,
      column: :updated_by_id,
      on_delete: :nullify
    )
  end

  def down
    remove_foreign_key_without_error(:merge_requests, column: :updated_by_id)
    remove_concurrent_index(:merge_requests, :updated_by_id)
  end
end
