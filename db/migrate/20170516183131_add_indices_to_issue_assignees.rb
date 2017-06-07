# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndicesToIssueAssignees < ActiveRecord::Migration
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

  def up
    add_concurrent_index :issue_assignees, [:issue_id, :user_id], unique: true, name: 'index_issue_assignees_on_issue_id_and_user_id'
    add_concurrent_index :issue_assignees, :user_id, name: 'index_issue_assignees_on_user_id'
    add_concurrent_foreign_key :issue_assignees, :users, column: :user_id, on_delete: :cascade
    add_concurrent_foreign_key :issue_assignees, :issues, column: :issue_id, on_delete: :cascade
  end

  def down
    remove_foreign_key :issue_assignees, column: :user_id
    remove_foreign_key :issue_assignees, column: :issue_id
    remove_concurrent_index :issue_assignees, [:issue_id, :user_id] if index_exists?(:issue_assignees, [:issue_id, :user_id])
    remove_concurrent_index :issue_assignees, :user_id if index_exists?(:issue_assignees, :user_id)
  end
end
