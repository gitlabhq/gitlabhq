# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MergeRequestsSourceProjectIdForeignKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  class MergeRequest < ActiveRecord::Base
    include EachBatch

    self.table_name = 'merge_requests'

    def self.with_orphaned_source_projects
      where('NOT EXISTS (SELECT true FROM projects WHERE merge_requests.source_project_id = projects.id)')
        .where('source_project_id IS NOT NULL')
    end
  end

  def up
    # We need to allow NULL values so we can nullify the column when the source
    # project is removed. We _don't_ want to remove the merge request, instead
    # the application will keep them but close them.
    change_column_null(:merge_requests, :source_project_id, true)

    MergeRequest.with_orphaned_source_projects.each_batch(of: 100) do |batch|
      batch.update_all(source_project_id: nil)
    end

    add_concurrent_foreign_key(
      :merge_requests,
      :projects,
      column: :source_project_id,
      on_delete: :nullify
    )
  end

  def down
    remove_foreign_key_without_error(:merge_requests, column: :source_project_id)
    change_column_null(:merge_requests, :source_project_id, false)
  end
end
