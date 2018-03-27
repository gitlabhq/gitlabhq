# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MergeRequestsAuthorIdForeignKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  class MergeRequest < ActiveRecord::Base
    include EachBatch

    self.table_name = 'merge_requests'

    def self.with_orphaned_authors
      where('NOT EXISTS (SELECT true FROM users WHERE merge_requests.author_id = users.id)')
        .where('author_id IS NOT NULL')
    end
  end

  def up
    # Replacing the ghost user ID logic would be too complex, hence we don't
    # redefine the User model here.
    ghost_id = User.select(:id).ghost.id

    MergeRequest.with_orphaned_authors.each_batch(of: 100) do |batch|
      batch.update_all(author_id: ghost_id)
    end

    add_concurrent_foreign_key(
      :merge_requests,
      :users,
      column: :author_id,
      on_delete: :nullify
    )
  end

  def down
    remove_foreign_key(:merge_requests, column: :author_id)
  end
end
