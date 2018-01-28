# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveAssigneeIdFromIssue < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # When a migration requires downtime you **must** uncomment the following
  # constant and define a short and easy to understand explanation as to why the
  # migration requires downtime.
  # DOWNTIME_REASON = ''

  # When using the methods "add_concurrent_index", "remove_concurrent_index" or
  # "add_column_with_default" you must disable the use of transactions
  # as these methods can not run in an existing transaction.
  # When using "add_concurrent_index" or "remove_concurrent_index" methods make sure
  # that either of them is the _only_ method called in the migration,
  # any other changes should go in a separate migration.
  # This ensures that upon failure _only_ the index creation or removing fails
  # and can be retried or reverted easily.
  #
  # To disable transactions uncomment the following line and remove these
  # comments:
  disable_ddl_transaction!

  class Issue < ActiveRecord::Base
    self.table_name = 'issues'

    include ::EachBatch
  end

  def up
    remove_column :issues, :assignee_id
  end

  def down
    add_column :issues, :assignee_id, :integer
    add_concurrent_index :issues, :assignee_id

    update_value = Arel.sql('(SELECT user_id FROM issue_assignees WHERE issue_assignees.issue_id = issues.id LIMIT 1)')

    # This is only used in the down step, so we can ignore the RuboCop warning
    # about large tables, as this is very unlikely to be run on GitLab.com
    update_column_in_batches(:issues, :assignee_id, update_value) # rubocop:disable Migration/UpdateLargeTable
  end
end
