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

    threads = []
    threads << delete_project_orphans(:events, :project_id)
    threads << delete_project_orphans(:issues, :project_id)
    threads << delete_project_orphans(:merge_requests, :target_project_id)
    threads << delete_project_orphans(:forked_project_links, :forked_to_project_id)
    threads << delete_project_orphans(:services, :project_id)
    threads << delete_project_orphans(:notes, :project_id)
    threads.map(&:join)

    # Rebuild indexes
    add_index :issues, [:project_id, :iid], unique: true
    add_index :issues, :assignee_id
    add_index :issues, :author_id
    add_index :issues, :confidential
    add_index :issues, :created_at
    add_index :issues, :deleted_at
    add_index :issues, :due_date
    add_index :issues, :milestone_id
    add_index :issues, :state
    add_index :events, :action
    add_index :events, :author_id
    add_index :events, :created_at
    add_index :events, :project_id
    add_index :events, :target_id
    add_index :events, :target_type

    # These already exist but don't specify on_delete: cascade, so we'll re-add them.
    remove_foreign_key :boards, :projects
    remove_foreign_key :lists, :boards
    remove_foreign_key :lists, :labels
    remove_foreign_key :protected_branch_merge_access_levels, :protected_branches
    remove_foreign_key :protected_branch_push_access_levels, :protected_branches

    # Merge Requests for target project and should be removed with it.
    # Merge Requests from source project should be kept when source project was removed.
    add_foreign_key :merge_requests, :projects, column: :target_project_id, on_delete: :cascade

    add_foreign_key :forked_project_links, :projects, column: :forked_to_project_id, on_delete: :cascade
    add_foreign_key :boards, :projects, on_delete: :cascade
    add_foreign_key :lists, :boards, on_delete: :cascade
    add_foreign_key :services, :projects, on_delete: :cascade
    add_foreign_key :notes, :projects, on_delete: :cascade
    add_foreign_key :events, :projects, on_delete: :cascade
    add_foreign_key :todos, :notes, on_delete: :cascade
    add_foreign_key :merge_request_diffs, :merge_requests, on_delete: :cascade
    add_foreign_key :issues, :projects, on_delete: :cascade
    add_foreign_key :labels, :projects, on_delete: :cascade
    add_foreign_key :lists, :labels, on_delete: :cascade
    add_foreign_key :label_links, :labels, on_delete: :cascade
    add_foreign_key :milestones, :projects, on_delete: :cascade
    add_foreign_key :snippets, :projects, on_delete: :cascade
    add_foreign_key :web_hooks, :projects, on_delete: :cascade
    add_foreign_key :protected_branch_merge_access_levels, :protected_branches, on_delete: :cascade
    add_foreign_key :protected_branch_push_access_levels, :protected_branches, on_delete: :cascade
    add_foreign_key :users_star_projects, :projects, on_delete: :cascade
    add_foreign_key :releases, :projects, on_delete: :cascade
    add_foreign_key :lfs_objects_projects, :projects, on_delete: :cascade
    add_foreign_key :project_group_links, :projects, on_delete: :cascade
    add_foreign_key :todos, :projects, on_delete: :cascade
    add_foreign_key :deployments, :projects, on_delete: :cascade
    add_foreign_key :environments, :projects, on_delete: :cascade
    add_foreign_key :ci_builds, :projects, column: :gl_project_id, on_delete: :cascade
    add_foreign_key :ci_runner_projects, :projects, column: :gl_project_id, on_delete: :cascade
    add_foreign_key :ci_variables, :projects, column: :gl_project_id, on_delete: :cascade
    add_foreign_key :ci_trigger_requests, :ci_triggers, column: :trigger_id, on_delete: :cascade
    add_foreign_key :ci_triggers, :projects, column: :gl_project_id, on_delete: :cascade
    add_foreign_key :ci_trigger_requests, :ci_commits, column: :commit_id, on_delete: :cascade
    add_foreign_key :ci_commits, :projects, column: :gl_project_id, on_delete: :cascade
    add_foreign_key :project_features, :projects, on_delete: :cascade
    add_foreign_key :project_import_data, :projects, on_delete: :cascade
  end

  def down
    remove_foreign_key :merge_requests, column: :target_project_id
    remove_foreign_key :forked_project_links, column: :forked_to_project_id
    remove_foreign_key :boards, :projects
    remove_foreign_key :lists, :boards
    remove_foreign_key :services, :projects
    remove_foreign_key :notes, :projects
    remove_foreign_key :events, :projects
    remove_foreign_key :todos, :notes
    remove_foreign_key :merge_request_diffs, :merge_requests
    remove_foreign_key :issues, :projects
    remove_foreign_key :labels, :projects
    remove_foreign_key :lists, :labels
    remove_foreign_key :label_links, :labels
    remove_foreign_key :milestones, :projects
    remove_foreign_key :snippets, :projects
    remove_foreign_key :web_hooks, :projects
    remove_foreign_key :protected_branch_merge_access_levels, :protected_branches
    remove_foreign_key :protected_branch_push_access_levels, :protected_branches
    remove_foreign_key :users_star_projects, :projects
    remove_foreign_key :releases, :projects
    remove_foreign_key :lfs_objects_projects, :projects
    remove_foreign_key :project_group_links, :projects
    remove_foreign_key :todos, :projects
    remove_foreign_key :deployments, :projects
    remove_foreign_key :environments, :projects
    remove_foreign_key :ci_builds, column: :gl_project_id
    remove_foreign_key :ci_runner_projects, column: :gl_project_id
    remove_foreign_key :ci_variables, column: :gl_project_id
    remove_foreign_key :ci_trigger_requests, column: :trigger_id
    remove_foreign_key :ci_triggers, column: :gl_project_id
    remove_foreign_key :ci_trigger_requests, column: :commit_id
    remove_foreign_key :ci_commits, column: :gl_project_id
    remove_foreign_key :project_features, :projects
    remove_foreign_key :project_import_data, :projects

    add_foreign_key :boards, :projects
    add_foreign_key :lists, :boards
    add_foreign_key :lists, :labels
    add_foreign_key :protected_branch_merge_access_levels, :protected_branches
    add_foreign_key :protected_branch_push_access_levels, :protected_branches
  end

  def remove_foreign_key(*args)
    super(*args)
  rescue ArgumentError
    # Ignore if the foreign key doesn't exists
  end

  private

  def delete_project_orphans(table_name, reference_column)
    # select all soft-deleted issuables with no matching project
    select_query = <<-EOF
SELECT id FROM #{table_name}
WHERE NOT EXISTS (SELECT 1 FROM projects WHERE projects.id = #{table_name}.#{reference_column})
LIMIT 50000
EOF

    # Eeach thread is a new session, so we must dissable statement timeout
    # on each of them. Also notice that these queries are executed in a new
    # transaction. That should be ok, since we are removing orphan records.
    Thread.new do
      transaction do
        disable_statement_timeout

        # MySQL doesn't allow you to use the table from the DELETE in the subquery.
        # You can however use the table in a subquery inside the subquery (see
        # http://www.mysqlfaqs.net/mysql-errors/1093-you-can-not-specify-target-table-comments-for-update-in-from-clause),
        # which seems to be perfectly fine. What's the point of the restriction then, you ask? Beats me.
        loop do
          deleted = delete "DELETE FROM #{table_name} WHERE id IN (SELECT id FROM (#{select_query}) AS t)"
          break if deleted == 0
        end
      end

      ActiveRecord::Base.clear_active_connections!
    end
  end
end
