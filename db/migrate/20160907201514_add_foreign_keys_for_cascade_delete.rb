# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddForeignKeysForCascadeDelete < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = true

  DOWNTIME_REASON = <<-HEREDOC
    According to https://gocardless.com/blog/zero-downtime-postgres-migrations-the-hard-parts
    adding a foreign key needs to acquire an AccessExclusive lock. Since we're
    adding foreign keys in large, heavily used tables, this migration will require
    downtime.
  HEREDOC

  TABLES = [
    [:boards, :projects, :project_id],
    [:ci_commits, :projects, :gl_project_id],
    [:ci_runner_projects, :projects, :gl_project_id],
    [:ci_trigger_requests, :ci_commits, :commit_id],
    [:ci_trigger_requests, :ci_triggers, :trigger_id],
    [:ci_triggers, :projects, :gl_project_id],
    [:ci_variables, :projects, :gl_project_id],
    [:deployments, :projects, :project_id],
    [:environments, :projects, :project_id],
    [:events, :projects, :project_id],
    [:forked_project_links, :projects, :forked_to_project_id],
    [:issues, :projects, :project_id],
    [:label_links, :labels, :label_id],
    [:labels, :projects, :project_id],
    [:lfs_objects_projects, :projects, :project_id],
    [:lists, :boards, :board_id],
    [:lists, :labels, :label_id],
    [:merge_requests, :projects, :target_project_id],
    [:merge_request_diffs, :merge_requests, :merge_request_id],
    [:milestones, :projects, :project_id],
    [:notes, :projects, :project_id],
    [:project_features, :projects, :project_id],
    [:project_group_links, :projects, :project_id],
    [:project_import_data, :projects, :project_id],
    [:protected_branch_merge_access_levels, :protected_branches, :protected_branch_id],
    [:protected_branch_push_access_levels, :protected_branches, :protected_branch_id],
    [:releases, :projects, :project_id],
    [:services, :projects, :project_id],
    [:snippets, :projects, :project_id],
    [:todos, :notes, :note_id],
    [:todos, :projects, :project_id],
    [:users_star_projects, :projects, :project_id],
    [:web_hooks, :projects, :project_id],
  ]

  def up
    disable_statement_timeout

    # Remove indexes to speed up orphan removal. We'll rebuild them after.
    remove_index :issues, column: [:project_id, :iid] if index_exists?(:issues, [:project_id, :iid])
    remove_index :issues, :assignee_id if index_exists?(:issues, :assignee_id)
    remove_index :issues, :author_id if index_exists?(:issues, :author_id)
    remove_index :issues, :confidential if index_exists?(:issues, :confidential)
    remove_index :issues, :created_at if index_exists?(:issues, :created_at)
    remove_index :issues, :deleted_at if index_exists?(:issues, :deleted_at)
    remove_index :issues, :due_date if index_exists?(:issues, :due_date)
    remove_index :issues, :milestone_id if index_exists?(:issues, :milestone_id)
    remove_index :issues, :state if index_exists?(:issues, :state)
    remove_index :events, :action if index_exists?(:events, :action)
    remove_index :events, :author_id if index_exists?(:events, :author_id)
    remove_index :events, :created_at if index_exists?(:events, :created_at)
    remove_index :events, :project_id if index_exists?(:events, :project_id)
    remove_index :events, :target_id if index_exists?(:events, :target_id)
    remove_index :events, :target_type if index_exists?(:events, :target_type)

    # These already exist but don't specify on_delete: cascade, so we'll re-add them.
    remove_foreign_key :boards, :projects
    remove_foreign_key :lists, :boards
    remove_foreign_key :lists, :labels
    remove_foreign_key :protected_branch_merge_access_levels, :protected_branches
    remove_foreign_key :protected_branch_push_access_levels, :protected_branches

    TABLES.each_slice(8) do |slice|
      threads = slice.map do |(source_table, target_table, column)|
        Thread.new do
          delete_project_orphans(source_table, target_table, column)
        end
      end

      threads.each(&:join)

      # Foreign keys can not be added in parallel as Rails' constraint name
      # generation code is not thread-safe.
      slice.each do |(source_table, target_table, column)|
        add_foreign_key(source_table,
                        target_table,
                        column: column,
                        on_delete: :cascade)
      end
    end

    # Rebuild indexes
    add_concurrent_index :issues, [:project_id, :iid], unique: true
    add_concurrent_index :issues, :assignee_id
    add_concurrent_index :issues, :author_id
    add_concurrent_index :issues, :confidential
    add_concurrent_index :issues, :created_at
    add_concurrent_index :issues, :deleted_at
    add_concurrent_index :issues, :due_date
    add_concurrent_index :issues, :milestone_id
    add_concurrent_index :issues, :state
    add_concurrent_index :events, :action
    add_concurrent_index :events, :author_id
    add_concurrent_index :events, :created_at
    add_concurrent_index :events, :project_id
    add_concurrent_index :events, :target_id
    add_concurrent_index :events, :target_type
  end

  def down
    TABLES.each do |(source_table, target_table, column)|
      remove_foreign_key(source_table, column: column)
    end

    # Re-add these without a cascading delete.
    add_foreign_key :boards, :projects
    add_foreign_key :lists, :boards
    add_foreign_key :lists, :labels
    add_foreign_key :protected_branch_merge_access_levels, :protected_branches
    add_foreign_key :protected_branch_push_access_levels, :protected_branches
  end

  private

  def delete_project_orphans(source_table, target_table, reference_column)
    # select all soft-deleted issuables with no matching project
    select_query = <<-EOF
SELECT id FROM #{source_table}
WHERE NOT EXISTS (
    SELECT 1
    FROM #{target_table}
    WHERE #{target_table}.id = #{source_table}.#{reference_column}
)
LIMIT 50000
EOF

    # Eeach thread is a new session, so we must dissable statement timeout
    # on each of them. Also notice that these queries are executed in a new
    # transaction. That should be ok, since we are removing orphan records.
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        connection.transaction do
          disable_statement_timeout

          # MySQL doesn't allow you to use the table from the DELETE in the subquery.
          # You can however use the table in a subquery inside the subquery (see
          # http://www.mysqlfaqs.net/mysql-errors/1093-you-can-not-specify-target-table-comments-for-update-in-from-clause),
          # which seems to be perfectly fine. What's the point of the restriction then, you ask? Beats me.
          loop do
            deleted = connection.delete "DELETE FROM #{source_table} WHERE id IN (SELECT id FROM (#{select_query}) AS t)"
            break if deleted == 0
          end
        end
      end
    end
  end
end
